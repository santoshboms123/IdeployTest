/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public class roSignatureHandler {
    
    @AuraEnabled 
    public static void saveSign(String base64Data, String contentType, string recordid) { 
        system.debug('recordid'+recordid);
        Resource_Allocation__c RA = new Resource_Allocation__c(); 
        if(Schema.sObjectType.Resource_Allocation__c.fields.Name.isAccessible()){
            RA =[SELECT Id,Name FROM Resource_Allocation__c WHERE id= :recordid limit 1]; 
        } 
        
        if(RA != null){
            base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');        
            Attachment a = new Attachment();
            a.parentId = RA.Id;
            a.Body = EncodingUtil.base64Decode(base64Data);        
            a.Name = RA.Name+'Signature.png';
            a.ContentType = contentType;   
            // Santosh to review and see how to add is creatable for attachments  
            if(roSecurityHandler.checkObject('Attachment',roSecurityHandler.permissionLevel.ISCREATABLE)){

               insert a;  
            }    
            
        }
              
    }

}