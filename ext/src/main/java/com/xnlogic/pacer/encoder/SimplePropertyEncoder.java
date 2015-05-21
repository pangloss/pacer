package com.xnlogic.pacer.encoder;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.jruby.RubyArray;
import org.yaml.snakeyaml.Yaml;



/**
 * Convert an object (coming from JRuby code) to an object that 
 * can be saved in a graph database.
 */
public class SimplePropertyEncoder {

	private static final String PREFIX_YAML     = " jaml ";
	private static final String PREFIX_TIME     = " utcT ";
	private static final String PREFIX_TIME_UTC = " time ";

	private enum ArrayType {LONG, DOUBLE, STRING, BOOLEAN, MIXED_LONG_AND_DOUBLE, OBJECT};

	private static DateFormat dateFormatterWithTimezone    = new SimpleDateFormat("y-M-d H:m:s.S z");
	private static DateFormat dateFormatterWithoutTimezone = new SimpleDateFormat("y-M-d H:m:s.S");

	private static Yaml yaml = new Yaml();


	//=========================================================================
	// Encode/Decode methods
	
	// Least specific implementations - Argument and return type are both of type Object.
	// These methods are a "fall-back option".
	
	public static Object encodeProperty(Object value){
		if(value == null){
			return null;
		}
		if(value instanceof RubyArray){
			return encodeProperty((RubyArray)value);
		} else {
			return encodePropertyUsingFallbackOption(value);
		}
	}

	public static Object decodeProperty(Object value) throws ParseException {
		if(value == null){
			return value;
		}
		if(value.getClass().isArray()){
			return value;
		}
		throw new UnsupportedOperationException();
	}


	// Specific implementations
	// Some Java types (boolean, long, double, String and Date) have equivalent JRuby types. 
	// In these cases, encoding/decoding using Java is faster. 

	public static boolean encodeProperty(boolean value){
		return value;
	}

	public static boolean decodeProperty(boolean value){
		return value;
	}

	public static long encodeProperty(long value){
		return value;
	}

	public static long decodeProperty(long value){
		return value;
	}

	public static double encodeProperty(double value){
		return value;
	}

	public static double decodeProperty(double value){
		return value;
	}

	/**
	 * NOTE: Although this method is implemented in Java, it will
	 * perform better when implemented in JRuby - The time it takes to 
	 * convert a JRuby string to a Java string is relative to the string's length, and
	 * usually is more expensive than performing the computation in JRuby.
	 */
	public static String encodeProperty(String value){
		if(value == null){
			return null;
		}
		value = value.trim();
		return value.isEmpty() ? null : value;
	}

	public static Object decodeProperty(String value) throws ParseException{
		if(value == null){
			return null;
		}
		if(! value.startsWith(" ")){
			return value;
		}

		if(value.startsWith(PREFIX_TIME)){
			return dateFormatterWithTimezone.parseObject(value.substring(PREFIX_TIME.length()));
		} else if(value.startsWith(PREFIX_TIME_UTC)){
			return dateFormatterWithoutTimezone.parseObject(value.substring(PREFIX_TIME_UTC.length()));
		} else if(value.startsWith(PREFIX_YAML)){
			return decodePropertyUsingFallbackOption(value.substring(PREFIX_YAML.length()));
		} else {
			throw new IllegalArgumentException("Unrecognized prefix for string '" + value + "'.");
		}
	}

	public static String encodeProperty(Date value, boolean isUTC){
		if(value == null){
			return null;
		}
		if(isUTC){
			return PREFIX_TIME_UTC + dateFormatterWithoutTimezone.format(value);
		} else {
			return PREFIX_TIME + dateFormatterWithTimezone.format(value);
		}
	}

	public static String encodeProperty(Date value){
		return encodeProperty(value, false);
	}
	
	public static Date decodeProperty(Date value){
		return value;
	}

	
	//-------------------------------------------------------------------------
	// Use YAML encoding as a fall-back option (mainly for arrays of mixed simple types)
	
	
	private static String encodePropertyUsingFallbackOption(Object value){
		return PREFIX_YAML + yaml.dump(value);
	}


	private static Object decodePropertyUsingFallbackOption(String encoded){
		return yaml.load(encoded);
	}
	
	//-------------------------------------------------------------------------
	// Arrays
	// By encoding arrays using Java (instead of Ruby), we get a huge performance boost.


	public static Object encodeProperty(RubyArray value){
		if(value == null){
			return null;
		}
		int length = (int) value.length().getLongValue(); // NOTE: JRuby fixnum don't seem to have getIntValue() method

		// Empty array is a special case
		if(length == 0){
			return new long[0];
		}

		ArrayType arrayType = getArrayType(value);
		
		switch (arrayType) {
		case LONG:
			long[] longArray = new long[length];
			for (int i = 0; i < longArray.length; i++) {
				longArray[i] = (Long) value.get(i);
			}
			return longArray;
			
		case DOUBLE:
			double[] doubleArray = new double[length];
			for (int i = 0; i < doubleArray.length; i++) {
				doubleArray[i] = (Double) value.get(i);
			}
			return doubleArray;
			
		case STRING:
			String[] stringArray = new String[length];
			for (int i = 0; i < stringArray.length; i++) {
				stringArray[i] = (String) value.get(i);
			}
			return stringArray;
			
		case MIXED_LONG_AND_DOUBLE:
			doubleArray = new double[length];
			for (int i = 0; i < doubleArray.length; i++) {
				Object item = value.get(i);
				if (item instanceof Long){
					doubleArray[i] = (Long) value.get(i);
				} else {
					doubleArray[i] = (Double) value.get(i);
				}
			}
			return doubleArray;
			
		case BOOLEAN:
			boolean[] booleanArray = new boolean[length];
			for (int i = 0; i < booleanArray.length; i++) {
				booleanArray[i] = (Boolean) value.get(i);
			}
			return booleanArray;
			
		default:
			return encodePropertyUsingFallbackOption(value);
		}
	}



	/**
	 * Resolve the type of this array, by checking the type of all of its elements.
	 * 
	 * @param array A NON-EMPTY array.
	 */
	private static ArrayType getArrayType(RubyArray array){
		ArrayType arrayType = getArrayType(array.get(0));

		for (int i = 1; i < array.length().getLongValue(); i++) {
			ArrayType itemType = getArrayType(array.get(i));

			if(arrayType != itemType){
				if(isNumber(arrayType) && isNumber(itemType)){
					arrayType = ArrayType.MIXED_LONG_AND_DOUBLE;
				} else {
					return ArrayType.OBJECT;
				}
			}
		}

		return arrayType;
	}

	private static boolean isNumber(ArrayType type){
		return type == ArrayType.LONG || type == ArrayType.DOUBLE || type == ArrayType.MIXED_LONG_AND_DOUBLE;
	}

	private static ArrayType getArrayType(Object singleItem){
		if(singleItem instanceof Long){
			return ArrayType.LONG;
		} else if(singleItem instanceof String){
			return ArrayType.STRING;
		} else if(singleItem instanceof Double){
			return ArrayType.DOUBLE;
		} else if(singleItem instanceof Boolean){
			return ArrayType.BOOLEAN;
		} else {
			return ArrayType.OBJECT;
		}
	}
}
