/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public class roResourceOptimizerSetupController {
    @AuraEnabled(cacheable=true)
    public static List<profile> getProfiles() {
        return [SELECT Id, Name, UserType, UserLicenseId, Description FROM Profile WHERE UserType = 'Standard']; 
    }
    
    @AuraEnabled
    public static ResourceOptimizerConfig__c getROSetupConfig(){
        ResourceOptimizerConfig__c roConfigRecord = ResourceOptimizerConfig__c.getValues(UserInfo.getOrganizationId()); // ResourceOptimizerConfig__c.getOrgDefaults();  
        system.debug('roConfigRecord ===> ' + ResourceOptimizerConfig__c.getValues(UserInfo.getOrganizationId()));
        return roConfigRecord;
    }
    
    @AuraEnabled
    public static Integer createResources(List<string> lstProfiles){
        List<Resource__c> listResourcesToInsert = new List<Resource__c>();
        set<string> setProfileIds =  new set<string>();
        set<Id> setResourceIdsCreated = new set<Id>();
        Integer  numberOfResourcesCreated;
        
        for(string pId : lstProfiles){
            setProfileIds.add(pId);
        }
        
        map<Id, Resource__c> mapExistingResource = new map<Id, Resource__c>();
        for(Resource__c r: [SELECT Id, User__c FROM Resource__c WHERE User__c != null]){
            mapExistingResource.put(r.User__c, r);
        }
        
        List<Resource_Group__c> lstResourceGroups = [SELECT Id from Resource_Group__c WHERE Name = 'Default Group'];
        Resource_Group__c resourceDefaultGroup;
        if(lstResourceGroups.isEmpty()){
            resourceDefaultGroup = createResourceDefaultGroup('Default Group');
        }
        else{
            resourceDefaultGroup = lstResourceGroups[0];
        }
        
        for(User u: [SELECT Id, Name, FirstName, LastName, Address, Street, City, State, PostalCode, Country, Email, Phone, MobilePhone, ProfileId, UserType, TimeZoneSidKey FROM User WHERE ProfileId IN: setProfileIds AND IsActive = True]){            
            if(!mapExistingResource.keyset().contains(u.Id)){
                Resource__c newResource = new Resource__c();
                newResource.Resource_Group__c = resourceDefaultGroup.Id;
                newResource.Resource_Type__c = 'Internal';
                newResource.First_Name__c = u.FirstName;
                newResource.Last_Name__c = u.LastName;
                newResource.Email__c = u.Email;
                newResource.Phone__c = u.Phone;
                newResource.Street__c = u.Street;
                newResource.City__c = u.City;
                newResource.State_Province__c = u.State;
                newResource.Country__c = u.Country;
                newResource.Active__c = True;
                newResource.Resource_Time_Zone__c = u.TimeZoneSidKey;
                //newResource.Zip_Postal_code__c = u.PostalCode;
                newResource.User__c = u.Id;
                listResourcesToInsert.add(newResource);   
            }      
        }
        
        system.debug('listResourcesToInsert ==> ' + listResourcesToInsert);
        
        if(listResourcesToInsert.size()>0){
            Database.SaveResult[] srList = Database.insert(listResourcesToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    setResourceIdsCreated.add(sr.getId());
                }
                else {                                   
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        roResourceOptimizerUtility.logExceptionMessage(err.getMessage(), 'during resource creation from setup ', null);
                    }
                }
            }
        }
        
        if(!setResourceIdsCreated.isEmpty()){
            numberOfResourcesCreated = setResourceIdsCreated.size();
        }
        
        return numberOfResourcesCreated;
    }
    
    @AuraEnabled
    public static string upsertROConfig(String roWrapperJSONstring){ 
        Map<String, Object> fieldWithValuesMap = (Map<String, Object>)JSON.deserializeUntyped(roWrapperJSONstring);
        system.debug('*****fieldWithValuesMpa ==> ' + fieldWithValuesMap);
        ResourceOptimizerConfig__c roConfigRecord = new ResourceOptimizerConfig__c();
        Set<String> skipFieldSet = new Set<String>{'IsDeleted','CreatedDate','CreatedById','LastModifiedDate', 'SystemModstamp','LastModifiedById','Id'};
            
        if(fieldWithValuesMap.containsKey('Id')){
           roConfigRecord.Id = (Id)fieldWithValuesMap.get('Id');
        }
        else{
            roConfigRecord.SetupOwnerId = UserInfo.getOrganizationId();
        }       
                
        for(String fieldName : fieldWithValuesMap.keySet()){            
            if(skipFieldSet.contains(fieldName))
                continue;     
            
            if(fieldName == 'organisationBusinessHoursStartTime'){
                string bStartTime = (string)fieldWithValuesMap.get(fieldName);
                List<string> timeComponents = bStartTime.split(':');
                roConfigRecord.put('Business_Start_Hours__c', Integer.valueOf(timeComponents[0]));
                roConfigRecord.put('Business_Start_Minutes__c', Integer.valueOf(timeComponents[1]));           
            }
            else if(fieldName == 'organisationBusinessHoursEndTime'){
                string bEndTime = (string)fieldWithValuesMap.get(fieldName);
                List<string> timeComponents = bEndTime.split(':');
                roConfigRecord.put('Business_End_Hours__c', Integer.valueOf(timeComponents[0]));
                roConfigRecord.put('Business_End_Minutes__c', Integer.valueOf(timeComponents[1]));               
            }
            else if(fieldName == 'resourceStartTime'){
                string rStartTime = (string)fieldWithValuesMap.get(fieldName);
                List<string>timeComponents = rStartTime.split(':');
                roConfigRecord.put('Resource_Start_Hours__c', Integer.valueOf(timeComponents[0]));
                roConfigRecord.put('Resource_Start_Minutes__c', Integer.valueOf(timeComponents[1]));
            }
            else if(fieldName == 'resourceEndTime'){
                string rEndTime = (string)fieldWithValuesMap.get(fieldName);
                List<string>timeComponents = rEndTime.split(':');
                roConfigRecord.put('Resource_End_Hours__c', Integer.valueOf(timeComponents[0]));
                roConfigRecord.put('Resource_End_Minutes__c', Integer.valueOf(timeComponents[1]));
            }
            else if(fieldName == 'Break_Time_For_Each_Resource_In_Minutes__c'){
                roConfigRecord.put(fieldName,Integer.valueOf(fieldWithValuesMap.get(fieldName)));
            }
            else if(fieldName == 'Create_Efficiencies_For_Next_N_Days__c'){
                roConfigRecord.put(fieldName,Integer.valueOf(fieldWithValuesMap.get(fieldName)));
            }
            else{                
                roConfigRecord.put(fieldName,fieldWithValuesMap.get(fieldName));
            }  
        }
        upsert roConfigRecord; 
        return roConfigRecord.Id;
    }
    
   /* private static DateTime convertTimeToDateTime (string targetTime){
        Date todayDate = Date.today();                
        List<string>timeComponents = targetTime.split(':');
        Time newTimeInstance = Time.newInstance(Integer.valueOf(timeComponents[0]), Integer.valueOf(timeComponents[1]), 0, 0);
        DateTime targetDateTime = DateTime.newInstance(todayDate, newTimeInstance);
        return targetDateTime;
    }*/
    
    public static Resource_Group__c createResourceDefaultGroup(string groupName){
        Resource_Group__c resourceGroup = new Resource_Group__c();
        resourceGroup.Name = groupName;
        resourceGroup.Group_Type__c = 'Both';
        resourceGroup.Active__c = True;
        
        try{
            insert resourceGroup;
            return resourceGroup;
        }
        catch(exception ex){
            return null;
        }        
    }
    
    
}