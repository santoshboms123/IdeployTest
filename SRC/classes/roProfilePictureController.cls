/************************************************************************ 
Author : Sukku
Details: 
    Purpose : roProfilePictureController - Controller to handle Resource Profile picture display and capture on Resource Record detail. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roProfilePictureController {
     
    @AuraEnabled
    public static Attachment getProfilePicture(Id parentId) {
        // Get the Latest image Attachment attached against the Resource ID 
        if(roSecurityHandler.checkObject('Attachment', roSecurityHandler.permissionLevel.ISACCESSIBLE)){
            return [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
            WHERE parentid=:ParentId AND ContentType IN ('image/png', 'image/jpeg', 'image/gif') 
            ORDER BY LastModifiedDate DESC LIMIT 1];
        }else{
            throw new System.NoAccessException();
        }
    }
     
    @AuraEnabled
    public static Id saveAttachment(Id parentId, String fileName, String base64Data, String contentType) { 
        String AttachmentID = '';
 		Attachment attachment = new Attachment();
        attachment.parentId = parentId;
        attachment.body = EncodingUtil.base64Decode(base64Data);
        attachment.name = fileName;
        attachment.contentType = contentType;
        
        if(roSecurityHandler.checkObject('Attachment', roSecurityHandler.permissionLevel.ISCREATABLE)){
            
        insert attachment;
        AttachmentID = attachment.id ;
        }else{
            throw new System.NoAccessException();
        }
        if(AttachmentID != null && AttachmentID != ''){
            if(roSecurityHandler.checkObject('resource__c', roSecurityHandler.permissionLevel.ISUPDATABLE) && roSecurityHandler.checkField(new String[] {'Profile_Picture_URL__c'}, 'resource__c', roSecurityHandler.permissionLevel.ISUPDATABLE)){
                Resource__c ParentResource = [select id,Profile_Picture_URL__c from resource__c where id = :parentId];
                ParentResource.Profile_Picture_URL__c = '/servlet/servlet.FileDownload?file='+ AttachmentID ;
                update ParentResource ;   
            }else{
                throw new System.NoAccessException();
            }
        }
        return AttachmentID;
    }
}