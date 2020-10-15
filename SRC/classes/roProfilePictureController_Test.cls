/************************************************************************ 
Author : Sukku
Details: 
    Purpose : roProfilePictureController_Test - Test Class to cover roProfilePictureController
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roProfilePictureController_Test extends roTestDataFactory{
    testmethod static void roprofilepicturetest(){
        
        String fileData = 'I am String to be converted in base64 encoding!';
        String fileDateBase64 = EncodingUtil.base64Encode(Blob.valueOf(fileData));
        String mimetype = 'image/png';
        String fileName = 'SampleTest.png';
        
        List<Resource__c> r =  createresourceswithdefaultparent(1);
        
        ID returnID =   roProfilePictureController.saveAttachment(R[0].id, fileName, fileDateBase64, mimetype);
        Attachment att = [select id, parentId, contentType from attachment where parentId=: R[0].Id];
        system.debug('att==>'+att);
        system.debug(R[0].Profile_Picture_URL__c);
        Attachment A = roProfilePictureController.getProfilePicture(att.ParentId);
    }
}