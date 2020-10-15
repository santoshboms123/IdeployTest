/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public abstract class roTestDataFactory {
   
    public enum permissionSetType {roAdmin, roDispatcher, roResource}
    public static final Id DAILYUTILIZATIONRECTYPEID  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Daily Utilization').getRecordTypeId();
    public static final Id WEEKLYUTILIZATIONRECTYPEID  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Weekly Utilization').getRecordTypeId();
    public static final Id MONTHLYUTILIZATIONRECTYPEID  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Monthly Utilization').getRecordTypeId();
    public static final Id QUARTERLYUTILIZATIONRECTYPEID  = Schema.SObjectType.Resource_Utilization__c.getRecordTypeInfosByName().get('Quarterly Utilization').getRecordTypeId();
      
    //User creation
    public static List<User> createUsers( Integer numberOfUsers) {
        List<User> Users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

       for ( Integer i = 0 ; i < numberOfUsers ; i++ ) {
          Blob b = Crypto.GenerateAESKey(128);
          String h = EncodingUtil.ConvertTohex(b);
          String uid = h.SubString(0,8);
          User u = new User(Alias = uid, Email= uid + '@myorg.com', EmailEncodingKey='UTF-8', LastName='Ramtej', LanguageLocaleKey='en_US', 
              LocaleSidKey='en_US', ProfileId = p.Id,  TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com', CommunityNickname = uid);      
          Users.add(u);
        }
      
        return Users;
    }
    
     //User creation with LastName
    public static List<User> createUsers( Integer numberOfUsers, String lastName) {
        List<User> Users = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

       for ( Integer i = 0 ; i < numberOfUsers ; i++ ) {
          Blob b = Crypto.GenerateAESKey(128);
          String h = EncodingUtil.ConvertTohex(b);
          String uid = h.SubString(0,8);
          User u = new User(Alias = uid, Email= uid + '@myorg.com', EmailEncodingKey='UTF-8', LastName=lastName + i, LanguageLocaleKey='en_US', 
              LocaleSidKey='en_US', ProfileId = p.Id,  TimeZoneSidKey='America/New_York', UserName= uid + '@myorg.com', CommunityNickname = uid);      
          Users.add(u);
        }
      
        return Users;
    }

    //assign permission set to user
    public static void assignPermissionSetToUsers(permissionSetType permissionSetType, List<Id> userIds){
        Id permissionSetId = getPermissionSetId(permissionSetType);
        if(permissionSetId != null){
            List<PermissionSetAssignment> PermissionSetAssignmentList = new List<PermissionSetAssignment>();
            for(Id userId :userIds){
                PermissionSetAssignmentList.add(new PermissionSetAssignment(PermissionSetId = permissionSetId, AssigneeId = userId));
            }
            Database.insert(PermissionSetAssignmentList);
        }
    }

    public static Id getPermissionSetId(permissionSetType permissionSet){
        switch on permissionSet{
            when roAdmin{
                return [SELECT Id FROM PermissionSet WHERE Name = 'Resource_Optimizer_Admin'].Id;
            }
            when roDispatcher{
                return [SELECT Id FROM PermissionSet WHERE Name = 'Resource_Optimizer_Dispatcher'].Id;
            }
            when roResource{
                return [SELECT Id FROM PermissionSet WHERE Name = 'Resource_Optimizer_Resource'].Id;
            }
            when else {
                return null;
            }
        }
    }
    
    //Resource Groups 
    Public static List<Resource_group__c> createresourcegroups( Integer numberofgroups){
        List<Resource_group__c> resourcegroups = new List<Resource_group__c>();
        
        for ( Integer i = 0 ; i < numberofgroups ; i++ ) {
             Resource_group__c RG = new Resource_group__c( name = 'Test Resource Group' + Math.random(), Active__c = true);
            resourcegroups.add( RG);
		 }
        
        return resourcegroups ;
    }
    
    // Resource Groups with Default Parent
    
    Public static List<Resource_group__c> createresourcegroupswithdefaultparent( Integer numberofgroups){
        Resource_group__c Parent = new Resource_group__c(name = 'Default', Active__c = true);
        insert Parent;
        
        List<Resource_group__c> resourcegroups = new List<Resource_group__c>();
        
        for ( Integer i = 0 ; i < numberofgroups ; i++ ) {
             Resource_group__c RG = new Resource_group__c( name = 'Test Resource Group' + Math.random(), Active__c = true,Parent_Group__c = Parent.id);
            resourcegroups.add( RG);
		 }
        
        insert resourcegroups ;
        return resourcegroups ;
    }
    
    // Resources with Default Parent 
    
    Public static List<Resource__c> createresourceswithdefaultparent( Integer numberofresource){
        Resource_group__c Parent = new Resource_group__c(name = 'Default', Active__c = true);
        insert Parent;
        
        List<Resource__c> resources = new List<Resource__c>();
        
        for ( Integer i = 0 ; i < numberofresource ; i++ ) {
             Resource__c RG = new Resource__c(name = 'Test Resource' + Math.random(), Last_Name__c = 'Test Resource' + Math.random(), Active__c = true,Resource_Group__c = Parent.id);
            resources.add( RG);
		 }
        insert resources ; 
        return resources ;
    }
    
    // Resources with Custom Parent 
    
    Public static List<Resource__c> createresourceswithcustomparent( Integer numberofresource, Id parentid){
              
        List<Resource__c> resources = new List<Resource__c>();
        
        for ( Integer i = 0 ; i < numberofresource ; i++ ) {
             Resource__c RG = new Resource__c(First_name__c='Test', Last_Name__c = 'Test Resource' + Math.random(), Active__c = true,Resource_Group__c = parentid);
            resources.add( RG);
		 }
        
        insert resources ; 
        return resources ;
    }
    
    // Resource Secuirty Group 
    
    Public static Resource_Optimizer_Security__c createresourcegroupsecurity( Id userid, Id GroupId){
              
       Resource_Optimizer_Security__c RG = new Resource_Optimizer_Security__c( User__c = userid, Access_Level__c = 'Edit',Resource_Group__c = GroupId);
        
        insert RG; 
        return RG ;
    }
    
    Public static Resource_Optimizer_Security__c createresourceallocationparentsecurity( Id userid, Id RAPId){
              
       Resource_Optimizer_Security__c RG = new Resource_Optimizer_Security__c( User__c = userid, Access_Level__c = 'Edit',Resource_Allocation_parent__c = RAPId);
        insert RG; 
        return RG;
    }
    
}