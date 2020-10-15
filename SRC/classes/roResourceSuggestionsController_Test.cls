/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roResourceSuggestionsController_Test extends ROTestDataFactory{
	
    public static string skillId {get; set;}
    public static string ReservationId {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
     static void setup(){
            Id resOpSecurityResourceGroupRecTypeId = Schema.SObjectType.Resource_Optimizer_Security__c.getRecordTypeInfosByName().get('Resource Group').getRecordTypeId();
        //create dispatch user
        List<User> userList = createUsers(3);
        Database.insert(userList);
        //assign permission set to user
        dispatchUser = userList[0];
        assignPermissionSetToUsers(permissionSetType.roDispatcher, new List<Id>{dispatchUser.Id});
        adminUser = userList[1];
        assignPermissionSetToUsers(permissionSetType.roAdmin, new List<Id>{adminUser.Id});
        

        system.runAs(adminUser){
            //insert org config
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 0, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 23, Resource_End_Minutes__c = 59);
            insert config;
            //create resource
            List<Resource_Group__c> testgroup = createresourcegroups(1);
            insert testgroup; 
           	List<Resource__c> testresources = createresourceswithcustomparent(5,testgroup[0].id);
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = testgroup[0].id, 
            User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
            
            // create test data 
           Skills__c Sk = new Skills__c(name='TestSkill',Active__c=true,UniqueID__c='TSK123');
            insert SK;
            skillId = String.valueof(sk.id).substring(0,15);
            List<Resource_Skills__c> RSK = new List<Resource_Skills__c>();
            for(integer i =0; i<5 ; i++){
                Resource_Skills__c RS = new Resource_Skills__c(Resource__c =  testresources[i].id,Skill__c= sk.id,Skill_Level__c = i*10 );
                RSK.add(RS);
            }
            insert RSK;
            
            // Create Resource Allocation Parent 
            Resource_Allocation_Parent__c RAP = new Resource_Allocation_Parent__c (Name = 'Reservation',Parent_API_Name__c ='Reservation__c',
                                                                                   Parent_JSON__c ='{"startDateTimeFielAPI":"Startdatetime__c","soqlString":"SELECT Id,Name FROM Reservation__c","recordTypes":null,"recordTypeName":"Master","recordTypeId":"","recordTypeDeveloperName":"Master","recordNameAPI":"Name","recordIdAPI":"Id","objectLabel":"Reservation","objectAPIName":"Reservation__c","filterString":"","endDateTimeFielAPI":"EndDateTime__c","descriptionFieldAPI":null,"columns":[{"fieldValue":null,"fieldType":"ID","fieldLabel":"Res ID","fieldApiName":"Id"}]}');
            insert RAP;
            
            // Create Reservation reason
            Reservation_Reason__c RR = new Reservation_Reason__c(Name='Test Reason',Active__c=true,Calculate_Utilization__c=true);
            insert RR;
            //Create Reservation 
            Reservation__c RE = New Reservation__c(Startdatetime__c = system.now(),EndDateTime__c=system.now().addMinutes(15),Reason__c=RR.id,Resource__c=testresources[0].id);
            insert RE;
            ReservationId = RE.id;
            
            
           List<Resource_Allocation__c> RAS = new List<Resource_Allocation__c>();
            
            datetime teststartdatetime = system.now(); 
            datetime testEnddatetime = system.now().addMinutes(30); 
            datetime teststartdatetime2 = system.now().addMinutes(35); 
            datetime testEnddatetime2 = system.now().addMinutes(55); 
            
            for(integer i =0; i<2 ; i++){
               Resource_Allocation__c RA1 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime, Allocated_End_Datetime__c = testEnddatetime , Resource__c = testresources[i].id,Calculate_Utilization__c = true ); 
               Resource_Allocation__c RA2 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime2, Allocated_End_Datetime__c = testEnddatetime2 , Resource__c = testresources[i].id,Calculate_Utilization__c = true  ); 
           	RAS.add(RA1);
            RAS.add(RA2);    
            }
            insert RAS ; 
            system.debug('allocations'+[select id,name,resource__c,Allocated_Start_DateTime__c from Resource_Allocation__c]);
            System.debug('availability'+[select id,name,Available_Hours_Slots__c,Available_Hours__c,Booked_Time_Slots__c,Utilization__c from Resource_Utilization__c]);
            
        } 
     }
    
    Static testmethod void test_RScontroller(){
      setup();  
      resource_group__c RG = [select id,name from resource_group__c LIMIT 1] ;
      datetime teststartdatetime = system.now().addMinutes(60); 
        datetime testEnddatetime = system.now().addMinutes(75) ; 
        datetime Uteststartdatetime = system.now(); 
            datetime UtestEnddatetime = system.now().addMinutes(30); 
        string st = teststartdatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string et = testEnddatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string Ust = Uteststartdatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        string Uet = UtestEnddatetime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        //With Skills
      roResourceSuggestionsController.finalresponse FR = roResourceSuggestionsController.getresourcesdirect('',RG.id,skillId,skillId,st,et,4,false);
        // Without Skills
       roResourceSuggestionsController.finalresponse FR2 = roResourceSuggestionsController.getresourcesdirect('',RG.id,'','',st,et,4,false);
       // Unavailable times 
       roResourceSuggestionsController.finalresponse FR3 = roResourceSuggestionsController.getresourcesdirect('',RG.id,'','',Ust,Uet,4,false);   
        //Fetch Groups
        List<resource_group__c> FG = roResourceSuggestionsController.fetchgroups();
        //Fetch Skills
        List<Skills__c> FS = roResourceSuggestionsController.getskills();
        // Fetch Datetime 
        roResourceSuggestionsController.datetimeresponse FD = roResourceSuggestionsController.getdatetime('Reservation__c', ReservationId);
      
    }
}