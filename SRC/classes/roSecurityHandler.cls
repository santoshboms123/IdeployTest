/************************************************************************ 
Author : Santosh 
Details: 
    Purpose : roSecurityHandler is the Secuirty Utility class to verify CRUD in other apex classes
	Snippets : 
                roSecurityHandler.checkField(new String[] {'Field1','field2'},'Objectname',roSecurityHandler.permissionLevel.ISACCESSIBLE)
                roSecurityHandler.checkObject('Objectname',roSecurityHandler.permissionLevel.ISACCESSIBLE)
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roSecurityHandler {
   
    public enum permissionLevel {ISACCESSIBLE, ISDELETABLE, ISCREATABLE, ISUPDATABLE}

   public static boolean checkObject(String objName, permissionLevel permissiontype){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        SObjectType myObj = schemaMap.get(objName);

        if(permissiontype == permissionLevel.ISACCESSIBLE){
            if (myObj.getDescribe().isAccessible() ) { 
                return true; 
            }else{
                return false;
            }

        }else if(permissiontype == permissionLevel.ISCREATABLE){
            if (myObj.getDescribe().isCreateable()) { 
                return true; 
            }else{
                return false;
            }

        }else if(permissiontype == permissionLevel.ISUPDATABLE){
            if (myObj.getDescribe().isUpdateable()) { 
                return true; 
            }else{
                return false;
            }

        }else if(permissiontype == permissionLevel.ISDELETABLE){
           if (myObj.getDescribe().isdeletable()) { 
                return true; 
            }else{
                return false;
            } 

        }else{
            return false;
        }
       
   }

     public static boolean checkField(List<String> fieldNames, String objName, permissionLevel permissiontype){
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        SObjectType myObj = schemaMap.get(objName);
       if (myObj.getDescribe().isAccessible() ) { 
        boolean fieldcheck = true;
        for(string fieldName: fieldNames){
            SObjectField myField = myObj.getDescribe().fields.getMap().get(fieldName);
            if(permissiontype == permissionLevel.ISACCESSIBLE){
                if(!myField.getDescribe().isAccessible()){    
                    fieldcheck = false;
                }
    
            }else if(permissiontype == permissionLevel.ISCREATABLE){
                if (!myField.getDescribe().isCreateable()) { 
                    fieldcheck = false;
                }
    
            }else if(permissiontype == permissionLevel.ISUPDATABLE){
                if (!myField.getDescribe().isUpdateable()) { 
                    fieldcheck = false;
                }
    
            }

            }
            if(fieldcheck){
                return true;
            }else{
                return false;
            }

         }
         else{
           return false;
       }
   }
}