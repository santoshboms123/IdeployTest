/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
public with sharing class roResourceGroupHierarchyController {

    @auraenabled
    Public static string gethierarchy(string recordId){
      // string recordId = 'a0W1s000001YiUO';
       recordId = recordId.substring(0,15);
       List<resource_group__c> Allgroups = new List<resource_group__c>();
       List<resource__c> Allresources = new List<resource__c>();
       Map<string,resource__c> resourcemap = new map<string,resource__c>();
       Map<string,resource_group__c> resourcegroupmap = new map<string,resource_group__c>();
       Map<string,List<hierarchywrapper>> resourcewrappermap = new map<string,List<hierarchywrapper>>(); 
       
       if( roSecurityHandler.checkField(new String[] {'Name','parent_group__c'},'resource_group__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
         roSecurityHandler.checkObject('resource_group__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)){
             Allgroups = [select id,name,parent_group__c from resource_group__c];
       } 
       
       if(roSecurityHandler.checkField(new String[] {'Name','First_name__c','last_name__c','role__c','resource_group__c'},'resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE)&&
         roSecurityHandler.checkObject('resource__c',roSecurityHandler.permissionLevel.ISACCESSIBLE) ){
            Allresources = [select id,name,First_name__c,last_name__c,role__c,resource_group__c from resource__c];
       }
        if(Allresources.size() > 0){
            for( resource__c R : allresources){
                if(R.resource_group__c != null){
                   resourcemap.put(string.valueOf(R.resource_group__c).substring(0,15)+string.valueOf(R.Id).substring(0,15),R); 
                }
                
            } 
        }
        
        system.debug('resourcemap'+resourcemap);
        
        if(allgroups.size() > 0){
            
            for(resource_group__c RG : allgroups){
               
                
                if(RG.Parent_Group__c != null){
                    resourcegroupmap.put(string.valueOf(RG.Parent_Group__c).substring(0,15)+string.valueOf(RG.Id).substring(0,15),RG);
                }
                
                resourcegroupmap.put(string.valueOf(RG.Id).substring(0,15),RG); 
                
                
               
                
              //  if(resourcemap.Keyset().contains(string.valueOf(RG.Id).substring(0,15))){
                    List<hierarchywrapper> HW = new List<hierarchywrapper>();
                    for(resource__c R1 : Allresources){
                        if(R1.resource_group__c == RG.id){
                            hierarchywrapper H = new hierarchywrapper();
                            H.label = R1.first_name__c + ' '+ R1.Last_Name__c;
                            H.metatext = R1.Role__c;
                            H.href = '/'+ R1.id ;
                            H.expanded = false ;
                            
                            HW.add(H);
                        }
                       resourcewrappermap.put(string.valueOf(RG.Id).substring(0,15),HW); 
                    }
                
                
                
            
            }
        }
        system.debug('resourcegroupmap'+resourcegroupmap);
        system.debug('resourcewrappermap'+resourcewrappermap);
      
      system.debug(resourcegroupmap);
        system.debug(resourcegroupmap.get(recordId));
        
       hierarchywrapper FinalHW =  getgroupwrapper(resourcegroupmap.get(recordId),1,Allgroups,resourcegroupmap,resourcewrappermap);
        String JsonS = '['+JSON.serializePretty(finalHW)+']' ;
      
        return JsonS;
    }
    
    public static hierarchywrapper getgroupwrapper(resource_group__c incominggroup, integer i,List<resource_group__c> ALLGs, Map<string,resource_group__c> RGmap,  Map<string,List<hierarchywrapper>> RWmap ){
       
       hierarchywrapper Htemp = new hierarchywrapper();
        Htemp.label = incominggroup.name ;
        Htemp.name = string.valueOf(i);
        if(i == 1){
         Htemp.expanded = true;   
        }else{
            Htemp.expanded = false;
        } 
        Htemp.metatext = '';
        Htemp.items = new List<hierarchywrapper>();
        
        for(resource_group__c Rtemp : ALLGs){
            if(Rtemp.Parent_Group__c!= null && Rtemp.Parent_Group__c == incominggroup.id){
              i = i + 1;
              system.debug(RGmap.get(string.valueof(Rtemp.id).substring(0,15)));
              system.debug(i +'-'+ALLGs +'-'+RGmap +'-'+RWmap);
                  
              Htemp.items.add(getgroupwrapper(RGmap.get(string.valueof(Rtemp.id).substring(0,15)),i,ALLGs,RGmap,RWmap));
             
            }
            
          }
        
        if(RWmap.get(string.valueof(incominggroup.id).substring(0,15)) != null){
           
            for(hierarchywrapper HWTemp : RWmap.get(string.valueof(incominggroup.id).substring(0,15))){
                if(HWTemp != null){
                   i = i + 1 ;
                HWTemp.name = string.valueOf(i);
                Htemp.items.add(HWTemp); 
                }   
            }
            
        }
        system.debug(RWmap);
         
        
        return Htemp;
    }
    
    public class hierarchywrapper{
        
       string label ;
       string name ; 
       string href ;
       string metatext;
       Boolean expanded;
       List<hierarchywrapper> items ;
    }
}