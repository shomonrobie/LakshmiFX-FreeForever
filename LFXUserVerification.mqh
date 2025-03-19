//+------------------------------------------------------------------+
//| UserVerification.mqh                                             |
//| Converted for MT4/MT5 compatibility                              |
//| Date: March 17, 2025                                             |
//+------------------------------------------------------------------+
#ifndef USER_VERIFICATION_MQH
#define USER_VERIFICATION_MQH

// Include necessary headers for MT4/MT5 compatibility
#ifdef __MQL4__
   #include <WinUser32.mqh>
   #define uchar char
   #define StringGetCharacter StringGetChar
   #define CharArrayToString CharToStr
#endif

#include <LakshmiFX\LFXErrorDesc.mqh>

//+------------------------------------------------------------------+
//| Check if user data exists via WebRequest                         |
//+------------------------------------------------------------------+
bool CheckIfUserDataExist(string userEmail, string username, long accountNumber, string expertName, long magicNumber)
{
   if ((userEmail == NULL && username == NULL) || accountNumber <= 0) {
      Print("Invalid input: Email/Username or Account Number is missing.");
      return false;
   }
   
   if (!IsValidEmail(userEmail)) {
      Print(expertName, "-", __FUNCTION__, " >", _Symbol, "> Your email address is not valid ", userEmail);
      return false;
   }     
   
   Print(userEmail, ">", username, ">", accountNumber);
   string regEntity = "";
   
   string headers = "";
   uchar data[], result[];
   string resultHeaders;
   string baseUrl = "https://lakshmifx.com/";
   string encodedEmail = URLEncode(userEmail);
   string encodedUsername = URLEncode(username);
   string url = baseUrl + "wp-json/lakshmifx/v1/verify-user?account=" + (string)accountNumber;

   if (userEmail != NULL) {
      url += "&email=" + encodedEmail;
      regEntity = userEmail;
   } else if (username != NULL) {
      url += "&username=" + encodedUsername;
      regEntity = username;
   }

   Print("Requesting: ", url);

   int timeout = 5000;
   ResetLastError();
   int res = WebRequest("GET", url, headers, timeout, data, result, resultHeaders);
   int errorCode = GetLastError();

   if (res == -1) {
      Print("WebRequest failed. Error code: ", errorCode);
      Print("Ensure " + baseUrl + " is added to allowed URLs in Tools > Options > Expert Advisors.");
      return false;
   }

   string response = CharArrayToString(result);
   Print("Response: ", response);

   if (StringFind(response, "\"exists\":1") >= 0) {
      Print(expertName, "> ", magicNumber, "> ", _Symbol, "> ", regEntity, " verified successfully!");
      if (!GlobalVariableSet("AccountVerified", 1.0)) {
         ResetLastError();
         Print(expertName, ">", magicNumber, ">", _Symbol, "> Though user ", regEntity, 
               " was found in the system, Global Variable cannot be set. ", GetLastError(), " - ", ErrorDescription(GetLastError()));
      }
      return true;      
   } else {
      Print(expertName, ">", magicNumber, ">", _Symbol, "> User ", regEntity, 
            " not found or inactive. Please register your Trading account at ", baseUrl, "/register");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Check account verification status                                |
//+------------------------------------------------------------------+
bool CheckAccountVerification(string username, string email, long accountNumber, string expertName, long magicNumber)
{
   if (GlobalVariableCheck("AccountVerified")) {
      if (StringLen(email) > 0 || StringLen(username) > 0) {
         Print(expertName, "> ", magicNumber, "> ", _Symbol, "> Greetings, ", 
               (StringLen(email) > 0) ? username : email, "!");
         return true; // Account verified and user data exists
      } else {
         Print(expertName, "> ", magicNumber, "> ", _Symbol, 
               "> Your account is verified, but username or email address does not exist. Please enter UserName and EmailAddress.");
         return false; // Account verified but missing user data, caller can create button
      }
   } else {
      if (StringLen(username) == 0 && StringLen(email) == 0) {
         Print(expertName, "> ", magicNumber, "> ", _Symbol, "> Your username/account is not verified.");
         return false; // No user data, caller can create button
      } else {
         if (CheckIfUserDataExist(email, username, accountNumber, expertName, magicNumber)) {
            Print(expertName, "> ", magicNumber, "> ", _Symbol, "> Greetings, ", 
                  (StringLen(username) > 0) ? username : email, "! Your account is registered. Thank you for using LakshmiFX. Good Luck!");
            return true; // Verification successful
         } else {
            Print(expertName, "> ", magicNumber, "> ", _Symbol, "> License not valid.");
            return false; // Verification failed, caller can create button
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Extract value from a string (simple JSON parsing)                |
//+------------------------------------------------------------------+
string ExtractValue(string text, string start, string end)
{
   int startPos = StringFind(text, start) + StringLen(start);
   int endPos = StringFind(text, end, startPos);
   if (startPos >= 0 && endPos > startPos) {
      return StringSubstr(text, startPos, endPos - startPos);
   }
   return "";
}

//+------------------------------------------------------------------+
//| URL encode function                                              |
//+------------------------------------------------------------------+
string URLEncode(string text)
{
   string result = "";
   for (int i = 0; i < StringLen(text); i++) {
      uchar ch = StringGetCharacter(text, i);
      if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || 
          ch == '-' || ch == '_' || ch == '.' || ch == '~') {
         result += CharToString(ch);
      } else {
         result += StringFormat("%%%02X", ch);
      }
   }
   return result;
}

//+------------------------------------------------------------------+
//| Validate email address                                           |
//+------------------------------------------------------------------+
bool IsValidEmail(string email)
{
   if (email == NULL || StringLen(email) == 0) return false;
   
   int atPos = StringFind(email, "@");
   if (atPos <= 0 || atPos == StringLen(email) - 1) return false;

   string localPart = StringSubstr(email, 0, atPos);
   string domainPart = StringSubstr(email, atPos + 1);

   if (StringLen(localPart) == 0 || StringLen(domainPart) == 0) return false;

   if (StringFind(domainPart, "@") >= 0) return false;

   int dotPos = StringFind(domainPart, ".");
   if (dotPos <= 0 || dotPos == StringLen(domainPart) - 1) return false;

   if (!ContainsOnlyValidDomainChars(domainPart)) return false;

   return true;
}

//+------------------------------------------------------------------+
//| Check if domain contains only valid characters                   |
//+------------------------------------------------------------------+
bool ContainsOnlyValidDomainChars(string domain)
{
   string validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-";
   for (int i = 0; i < StringLen(domain); i++) {
      if (StringFind(validChars, StringSubstr(domain, i, 1)) < 0) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Get account number (MT4/MT5 compatible)                          |
//+------------------------------------------------------------------+
long AccountNumber()
{
#ifdef __MQL4__
   return AccountNumber();
#else
   return AccountNumber(); // Built-in MQL5 function
#endif
}

//+------------------------------------------------------------------+
#endif // USER_VERIFICATION_MQH