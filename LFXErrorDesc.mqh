//+------------------------------------------------------------------+
//|                                             LakshmiErrorDesc.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property strict


// Error //

string ErrorDescription(int error_code)
  {
   string error_string = "";
//---
   switch(error_code)
     {
      //--- Trade server return codes
      case 10004:
         error_string = "Requote";
         break;
      case 10006:
         error_string = "Request rejected";
         break;
      case 10007:
         error_string = "Request canceled by trader";
         break;
      case 10008:
         error_string = "Order placed";
         break;
      case 10009:
         error_string = "Request executed";
         break;
      case 10010:
         error_string = "Request executed partially";
         break;
      case 10011:
         error_string = "Request processing error";
         break;
      case 10012:
         error_string = "Request timed out";
         break;
      case 10013:
         error_string = "Invalid request";
         break;
      case 10014:
         error_string = "Invalid request volume";
         break;
      case 10015:
         error_string = "Invalid request price";
         break;
      case 10016:
         error_string = "Invalid Stop orders in the request";
         break;
      case 10017:
         error_string = "Trading forbidden";
         break;
      case 10018:
         error_string = "Market is closed";
         break;
      case 10019:
         error_string = "Insufficient funds";
         break;
      case 10020:
         error_string = "Prices changed";
         break;
      case 10021:
         error_string = "No quotes to process the request";
         break;
      case 10022:
         error_string = "Invalid order expiration in the request";
         break;
      case 10023:
         error_string = "Order status changed";
         break;
      case 10024:
         error_string = "Too many requests";
         break;
      case 10025:
         error_string = "No changes in the request";
         break;
      case 10026:
         error_string = "Automated trading is disabled by trader";
         break;
      case 10027:
         error_string = "Automated trading is disabled by the client terminal";
         break;
      case 10028:
         error_string = "Request blocked for processing";
         break;
      case 10029:
         error_string = "Order or position frozen";
         break;
      case 10030:
         error_string = "The specified type of order execution by balance is not supported";
         break;
      case 10031:
         error_string = "No connection with trade server";
         break;
      case 10032:
         error_string = "Transaction is allowed for live accounts only";
         break;
      case 10033:
         error_string = "You have reached the maximum number of pending orders";
         break;
      case 10034:
         error_string = "You have reached the maximum order and position volume for this symbol";
         break;
      case 10035:
         error_string = "Incorrect or prohibited order type";
         break;
      case 10036:
         error_string = "Position with the specified POSITION_IDENTIFIER has already been closed";
         break;
      case 10038:
         error_string = "A close volume exceeds the current position volume";
         break;
      case 10039:
         error_string = "A close order already exists for a specified position";
         break;
      case 10040:
         error_string = "Position Limit reached.";
         break;
      case 10041:
         error_string = "The pending order activation request is rejected, the order is canceled.";
         break;
      case 10042:
         error_string = "The request is rejected, because the \'Only long positions are allowed\' rule is set for the symbol (POSITION_TYPE_BUY).";
         break;
      case 10043:
         error_string = "The request is rejected, because the \'Only short positions are allowed\' rule is set for the symbol (POSITION_TYPE_SELL).";
         break;
      case 10044:
         error_string = "The request is rejected, because the \'Only position closing is allowed\' rule is set for the symbol.";
         break;
      case 10045:
         error_string = "The request is rejected, because \'Position closing is allowed only by FIFO rule\' flag is set for the trading account (ACCOUNT_FIFO_CLOSE=true)";
         break;
      case 10046:
         error_string = "The request is rejected, because the \'Opposite positions on a single symbol are disabled\' rule is set for the trading account.";
         break;
      //--- Runtime errors
      case 0:  // The operation performed successfully
      case 4001:
         error_string = "Unexpected internal error";
         break;
      case 4002:
         error_string = "Incorrect parameter in the internal call of the client terminal function";
         break;
      case 4003:
         error_string = "Incorrect parameter in the call of the system function";
         break;
      case 4004:
         error_string = "Not enough memory to perform the system function";
         break;
      case 4005:
         error_string = "The structure contains string and/or dynamic array objects and/or structures with such objects and/or classes";
         break;
      case 4006:
         error_string = "Invalid type or size of the array or corrupted dynamic array object";
         break;
      case 4007:
         error_string = "Not enough memory to reallocate the array or an attempt to change the dynamic array size";
         break;
      case 4008:
         error_string = "Not enough memory to reallocate the string";
         break;
      case 4009:
         error_string = "Uninitialized string";
         break;
      case 4010:
         error_string = "Invalid time and/or date value";
         break;
      case 4011:
         error_string = "Requested array size exceeds 2 GB";
         break;
      case 4012:
         error_string = "Incorrect pointer";
         break;
      case 4013:
         error_string = "Incorrect pointer type";
         break;
      case 4014:
         error_string = "System function cannot be called";
         break;
      //-- Charts
      case 4101:
         error_string = "Incorrect chart identifier";
         break;
      case 4102:
         error_string = "Chart not responding";
         break;
      case 4103:
         error_string = "Chart not found";
         break;
      case 4104:
         error_string = "No Expert Advisor on the chart to handle the event";
         break;
      case 4105:
         error_string = "Chart opening error";
         break;
      case 4106:
         error_string = "Error when changing chart symbol and period";
         break;
      case 4107:
         error_string = "Incorrect timer value";
         break;
      case 4108:
         error_string = "Error when creating the timer";
         break;
      case 4109:
         error_string = "Incorrect chart property identifier";
         break;
      case 4110:
         error_string = "Error when creating the screenshot";
         break;
      case 4111:
         error_string = "Chart navigation error";
         break;
      case 4112:
         error_string = "Template application error";
         break;
      case 4113:
         error_string = "Subwindow with the specified indicator not found";
         break;
      case 4114:
         error_string = "Error when adding indicator to the chart";
         break;
      case 4115:
         error_string = "Error when removing indicator from the chart";
         break;
      case 4116:
         error_string = "The indicator not found in the specified chart";
         break;
      //-- Graphical objects
      case 4201:
         error_string = "Error when working with the graphical object";
         break;
      case 4202:
         error_string = "The graphical object not found";
         break;
      case 4203:
         error_string = "Incorrect identifier of the graphical object property";
         break;
      case 4204:
         error_string = "Unable to get the date corresponding to the value";
         break;
      case 4205:
         error_string = "Unable to get the value corresponding to the date";
         break;
      //-- MarketInfo
      case 4301:
         error_string = "Unknown symbol";
         break;
      case 4302:
         error_string = "The symbol not selected in MarketWatch";
         break;
      case 4303:
         error_string = "Incorrect symbol property identifier";
         break;
      case 4304:
         error_string = "Unknown time of the last tick (no ticks)";
         break;
      //-- Access to history
      case 4401:
         error_string = "Requested history not found!";
         break;
      case 4402:
         error_string = "Incorrect history property identifier";
         break;
      //-- Global_Variables
      case 4501:
         error_string = "Global variable of the client terminal not found";
         break;
      case 4502:
         error_string = "Global variable of the client terminal with this name already exists";
         break;
      case 4510:
         error_string = "Failed to send the message";
         break;
      case 4511:
         error_string = "Failed to play the sound";
         break;
      case 4512:
         error_string = "Incorrect program property identifier";
         break;
      case 4513:
         error_string = "Incorrect terminal property identifier";
         break;
      case 4514:
         error_string = "Failed to export the file by ftp";
         break;
      //-- Buffers of custom indicators
      case 4601:
         error_string = "Not enough memory to allocate indicator buffers";
         break;
      case 4602:
         error_string = "Incorrect index of the custom indicator buffer";
         break;
      //-- Custom indicator properties
      case 4603:
         error_string = "Incorrect custom indicator property identifier";
         break;
      //-- Account
      case 4701:
         error_string = "Incorrect account property identifier";
         break;
      case 4751:
         error_string = "Incorrect trading property identifier";
         break;
      case 4752:
         error_string = "The Expert Advisor is not allowed to trade";
         break;
      case 4753:
         error_string = "The position not found";
         break;
      case 4754:
         error_string = "The order not found";
         break;
      case 4755:
         error_string = "The trade not found";
         break;
      case 4756:
         error_string = "Failed to send the trade request";
         break;
      //-- Indicators
      case 4801:
         error_string = "Unknown symbol";
         break;
      case 4802:
         error_string = "Unable to create the indicator";
         break;
      case 4803:
         error_string = "Not enough memory to add the indicator";
         break;
      case 4804:
         error_string = "Unable to apply the indicator to another indicator";
         break;
      case 4805:
         error_string = "Error when adding the indicator";
         break;
      case 4806:
         error_string = "Requested data not found";
         break;
      case 4807:
         error_string = "Incorrect indicator handle";
         break;
      case 4808:
         error_string = "Invalid number of parameters when creating the indicator";
         break;
      case 4809:
         error_string = "No parameters to create the indicator";
         break;
      case 4810:
         error_string = "Custom indicator name should be the first parameter in the array";
         break;
      case 4811:
         error_string = "Invalid parameter type in the array when creating the indicator";
         break;
      case 4812:
         error_string = "Incorrect index of the requested indicator buffer";
         break;
      //-- Depth of market
      case 4901:
         error_string = "Unable to add the depth of market";
         break;
      case 4902:
         error_string = "Unable to delete the depth of market";
         break;
      case 4903:
         error_string = "Unable to get data from the depth of market";
         break;
      case 4904:
         error_string = "Error when subscribing to get new data from the depth of market";
         break;
      //-- File operations
      case 5001:
         error_string = "The number of files open at the same time cannot exceed 64";
         break;
      case 5002:
         error_string = "Invalid file name";
         break;
      case 5003:
         error_string = "File name too long";
         break;
      case 5004:
         error_string = "File opening error";
         break;
      case 5005:
         error_string = "Not enough memory to cache read";
         break;
      case 5006:
         error_string = "File deleting error";
         break;
      case 5007:
         error_string = "The file with this handle has already been closed or has never been opened";
         break;
      case 5008:
         error_string = "Incorrect file handle";
         break;
      case 5009:
         error_string = "The file must be open for writing";
         break;
      case 5010:
         error_string = "The file must be open for reading";
         break;
      case 5011:
         error_string = "The file must be open in binary mode";
         break;
      case 5012:
         error_string = "The file must be open in text mode";
         break;
      case 5013:
         error_string = "The file must be open in text mode or CSV format";
         break;
      case 5014:
         error_string = "The file must be open in CSV format";
         break;
      case 5015:
         error_string = "File reading error";
         break;
      case 5016:
         error_string = "String size must be specified for the file that is open in binary mode";
         break;
      case 5017:
         error_string = "There must be text file for string arrays and a binary file for all other arrays";
         break;
      case 5018:
         error_string = "This is not a file, it is a directory";
         break;
      case 5019:
         error_string = "The file does not exist";
         break;
      case 5020:
         error_string = "The file cannot be rewritten";
         break;
      case 5021:
         error_string = "Incorrect directory name";
         break;
      case 5022:
         error_string = "The directory does not exist";
         break;
      case 5023:
         error_string = "This is not a directory, it is a file";
         break;
      case 5024:
         error_string = "The directory cannot be deleted";
         break;
      case 5025:
         error_string = "Failed to clear the directory (can happen if one or more files is blocked and the deletion was not successful)";
         break;
      //-- String formatting
      case 5030:
         error_string = "No date in the string";
         break;
      case 5031:
         error_string = "Incorrect date in the string";
         break;
      case 5032:
         error_string = "Incorrect time in the string";
         break;
      case 5033:
         error_string = "Error converting string to date";
         break;
      case 5034:
         error_string = "Not enough memory for the string";
         break;
      case 5035:
         error_string = "String length is less than expected";
         break;
      case 5036:
         error_string = "Number too large, bigger than ULONG_MAX";
         break;
      case 5037:
         error_string = "Incorrect format string";
         break;
      case 5038:
         error_string = "The number of format specifiers is bigger than the number of parameters";
         break;
      case 5039:
         error_string = "The number of parameters is bigger than the number of format specifiers";
         break;
      case 5040:
         error_string = "Corrupted string type parameter";
         break;
      case 5041:
         error_string = "Position outside of the string";
         break;
      case 5042:
         error_string = "0 added to the end of the string, content-free operation";
         break;
      case 5043:
         error_string = "Unknown data type when converting to string";
         break;
      case 5044:
         error_string = "Corrupted string object";
         break;
      //-- Operations with arrays
      case 5050:
         error_string = "Cannot copy incompatible arrays. String array can only be copied to another string array and numeric array to another numeric array";
         break;
      case 5051:
         error_string = "The receiving array is declared as AS_SERIES and its size is not sufficient";
         break;
      case 5052:
         error_string = "Array too small, the starting position is outside of the array";
         break;
      case 5053:
         error_string = "Zero length array";
         break;
      case 5054:
         error_string = "The array must be numeric";
         break;
      case 5055:
         error_string = "The array must be one-dimensional";
         break;
      case 5056:
         error_string = "The time series cannot be used";
         break;
      case 5057:
         error_string = "The array must be of the double type";
         break;
      case 5058:
         error_string = "The array must be of the float type";
         break;
      case 5059:
         error_string = "The array must be of the long type";
         break;
      case 5060:
         error_string = "The array must be of the int type";
         break;
      case 5061:
         error_string = "The array must be of the short type";
         break;
      case 5062:
         error_string = "The array must be of the char type";
         break;
      //-- User errors
      default:
         error_string = "The error is undefined";
     }
//---
   return(error_string);
  }


      