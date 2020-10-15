/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/

public class roEfficiencyWrapper {   
     public Etable etable {get; set;}     
     
     public class Etable{
        @AuraEnabled public List<Header> header {get; set;}
        @AuraEnabled public List<map<string, string>> Body {get; set;} 
    }
    
    public class Header{
        @AuraEnabled public string key{get; set;}
        @AuraEnabled public string value{get; set;}
        @AuraEnabled public List<Childheader> Childheader {get; set;}
    }
    
     public class Childheader{
        @AuraEnabled public string key{get; set;}
        @AuraEnabled public string value{get; set;}
     }
}