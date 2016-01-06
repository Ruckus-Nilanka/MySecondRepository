/*******************************************************************************************
/* Ravi V - Global Reach Entitlement count automation  -  06/23/2014  */
*for POC purpose I'm making some chnages in the code to see if it works or not */
******************************************************************************************/
global class AccEntcountbatch implements Database.Batchable<sObject>
{
    // Declaring variables 
    public static Set<Id> SAMSList = new Set<id>();
    public static Set<Id> FlexeraList = new Set<id>();
    public static Set<Id> SPOTsList = new Set<id>();
    public static list<Id> accountIDList = new list<id>();
    public static Set<ID> AccountIDsSet = new set<id>();
    public  list<Account> accountList;
    public  list<Entitlement> lstent;
    public String query;
    public String Accountquery;
    public static String jobdate;
    List<Error_log__c> errorLogList = new List<Error_log__c>();
    public String errorMsgs = '';
    global Database.QueryLocator start(Database.BatchableContext BC)  
    {  
        query = 'select id, Sales_Order_Item__c, Sales_Order_Item__r.Product__r.Cloud_Product_Type__c,Sales_Order_Item__r.sales_order__r.Account__c,End_User_Account__c,Primary_Partner_Account__c from Entitlement where ';
        System.debug('Static query ***********'+query);
        jobdate = Entitlement_batch__c.getValues('GRBatchDate').Value__c;
        System.debug('jobdate *****************'+jobdate);
            
        if(jobdate != null)
        { 
            Datetime dt = Date.parse(jobdate);
            Datetime jobdate1 = dt.AddDays(1);
            string stringDate = jobdate1.month()+'/'+jobdate1.day()+'/'+jobdate1.year() ;
            Datetime temp = Date.parse(stringDate);
            temp = temp.AddDays(1);
            Date st2 = date.newinstance(temp.year(), temp.month(), temp.day());
             System.debug('jobdate1.day() ***********'+jobdate1.day());
            System.debug('dt date ***********'+dt);
            System.debug('jobdate1 ***********'+jobdate1);
            System.debug('st2 date ***********'+st2);
			
			// Added By Nilanka for POC //
			System.debug('dt date ***********'+dt);
            System.debug('jobdate1 ***********'+jobdate1);
            System.debug('st2 date ***********'+st2);
			
			
            
             System.debug('temp ***********'+temp);
            query = query+'  Sales_Order_Item__c!=null and Cloud_Product_Type__c!=null and (EndDate =today OR StartDate =today OR (lastmodifieddate >=:dt and lastmodifieddate <=today))';
        }
        else 
        {
            Datetime temp = datetime.now();
            Integer yearofdate=temp.year();
            string year =String.valueOf(yearofdate) ;
            string month = '1';
            string day = '1';
            string stringDate = month+'/'+day+'/'+year ;
            Datetime jobdate1 = Date.parse(stringDate);
            Date st2 = date.newinstance(jobdate1.year(), jobdate1.month(), jobdate1.day());
            System.debug('jobdate1 date ***********'+jobdate1);
            System.debug('temp ***********'+temp);
            query = query+' Sales_Order_Item__c!=null and Cloud_Product_Type__c!=null and (EndDate =:st2 OR StartDate =:st2 OR (lastmodifieddate >=:jobdate1 and lastmodifieddate <=:temp ))';
        }
        query = query + ' all rows';    
        System.debug('After merge query ***********'+query);
        lstent = Database.query(query);
          System.debug('lstent ******* '+lstent); 
        // Filtering product type through the sales order item. As result we will get last modified Entitlement related Accounts only
            
        for(Entitlement e: lstent)
        {
            System.debug('Entitlement *******'+e);
                   
            if(e.Sales_Order_Item__r.Product__r.Cloud_Product_Type__c =='SAM' )
            {
                if(e.End_User_Account__c!=null)
                    SAMSList.add(e.End_User_Account__c); 
                if(e.Primary_Partner_Account__c!=null && e.End_User_Account__c!=e.Primary_Partner_Account__c)
                    SAMSList.add(e.Primary_Partner_Account__c);
            }
                   
            else if(e.Sales_Order_Item__r.Product__r.Cloud_Product_Type__c =='Flexera')
            { 
                if(e.End_User_Account__c!=null)
                    FlexeraList.add(e.End_User_Account__c);
                if(e.Primary_Partner_Account__c!=null && e.End_User_Account__c!=e.Primary_Partner_Account__c)
                    FlexeraList.add(e.Primary_Partner_Account__c);
            }
                  
           else if(e.Sales_Order_Item__r.Product__r.Cloud_Product_Type__c =='SPOTs')
            { 
                if(e.End_User_Account__c!=null)
                    SPOTsList.add(e.End_User_Account__c);
                if(e.Primary_Partner_Account__c!=null && e.End_User_Account__c!=e.Primary_Partner_Account__c)
                    SPOTsList.add(e.Primary_Partner_Account__c);
            }
        }//End for
        
        accountIdList.addAll(SAMSList);
        accountIdList.addAll(FlexeraList);
        accountIdList.addAll(SPOTsList); 
        System.debug('accountIdList ******* '+accountIdList);  
        if(Test.isRunningTest()==false)                                       
        {Accountquery = 'select id,SAM__c,Flexera__c,SPOTs__c,SAM_Count__c,Flexera_Count__c,SPOTs_Count__c from account where id IN:accountIdList';}
        else
         {Accountquery = 'select id,SAM__c,Flexera__c,SPOTs__c,SAM_Count__c,Flexera_Count__c,SPOTs_Count__c from account where id IN:accountIdList limit 1';}    
        
        return Database.getQueryLocator(Accountquery);//Dynamic query return all Entitlement records based on last modified date given by custom settings
          
    } //End Start method
              
   
    global void execute(Database.BatchableContext BC,List<Account> scope)  
    {  
          // Used Set to avoid duplicate Account records
           List<Account> accountList = new List<Account>();
           list<Account> updateAccountList = new list<Account>();
           for(Sobject s : scope)  
                 {  
                   Account a = (Account)s;  
                   accountList.add(a);  
                  }
          System.debug('******* accountSet '+accountList);      
          List<AggregateResult> results;
           if(accountList != null && accountList.size() > 0)
                  {
                    for(Account temp :accountList)
                        {
                          if(temp!=null)
                          AccountIDsSet.add(temp.id);
                        }//End for
                   }//End if
        System.debug('******* AccountIDsSet '+AccountIDsSet);
               
        if(AccountIDsSet != null && AccountIDsSet.size() > 0) 
        { 
           // if(Test.isRunningTest()==false)
                results = new List<AggregateResult>([Select End_User_Account__c EU,Sales_Order_Item__r.Product__r.Cloud_Product_Type__c ProdType, count(id) cnt from entitlement where status='Active' and Sales_Order_Item__r.Product__r.Cloud_Product_Type__c!=null and  Sales_Order_Item__c!=null and End_User_Account__c IN:AccountIDsSet group by Sales_Order_Item__r.Product__r.Cloud_Product_Type__c,End_User_Account__c ]);
           // else
              //  results = new List<AggregateResult>([Select End_User_Account__c EU,Sales_Order_Item__r.Product__r.Cloud_Product_Type__c ProdType, count(id) cnt from entitlement where  End_User_Account__r.Do_Territory_Assignment__c=false and status='Active' and Sales_Order_Item__r.Product__r.Cloud_Product_Type__c!=null and  Sales_Order_Item__c!=null and End_User_Account__c IN:AccountIDsSet group by Sales_Order_Item__r.Product__r.Cloud_Product_Type__c,End_User_Account__c  limit 1 ]);
                    
        }   
      if(results.size() > 0)
      {
        for(Account ac:accountList)
        {
            System.debug('******* resultEnt '+results);  
            Integer i=0;
            // On Account setting flag and adding count 
                            for(AggregateResult resultEnt : results)  
                {
                	
                    if ((string)resultEnt.get('EU')==ac.id && (string)resultEnt.get('ProdType')=='SAM' )
                    {
                        ac.SAM__c = true;
                        ac.SAM_Count__c = (Integer)resultEnt.get('cnt');
                       i++;
                    }//End if
                }//End for 
           
                for(AggregateResult resultEnt : results)  
                {
                    System.debug('******* inside cnt  '+ (Integer)resultEnt.get('cnt'));
                    if ((string)resultEnt.get('EU')==ac.id && (string)resultEnt.get('ProdType')=='Flexera' )
                    {
                        ac.Flexera__c = true;
                        ac.Flexera_Count__c = (Integer)resultEnt.get('cnt');
                         i++;
                         System.debug('******* inside ac '+ac);
                        
                    }//End if
                }//End for  
           
                for(AggregateResult resultEnt : results)  
                {
                    if ((string)resultEnt.get('EU')==ac.id && (string)resultEnt.get('ProdType')=='SPOTs' )
                    {
                        ac.SPOTs__c = true;
                        ac.SPOTs_Count__c = (Integer)resultEnt.get('cnt');
                         i++;
                    }//End if
                }//End for 
           if(i == 0)
           {
           	if(ac.SAM_Count__c!= 0)
           	ac.SAM_Count__c = 0;
           	if(ac.Flexera_Count__c != 0)
           	ac.Flexera_Count__c = 0;
           	if(ac.SPOTs_Count__c != 0)
           	ac.SPOTs_Count__c = 0;
           }
         updateAccountList.add(ac);   
         System.debug('******* ac '+ac);
         }//End for    
         
       } 
         System.debug('******* updateAccountList '+updateAccountList);
        try 
        {
           
            Database.SaveResult[] SR = database.update(updateAccountList,false); // update accountList;                                              
            system.debug('After update ********* '+updateAccountList); 
            Integer recordid = 0;
                     
            for(Database.SaveResult err: SR) 
            {
                if (!err.isSuccess()) 
                {
                    System.debug(' $$$ ' + err.getId());
                    errormsgs += 'Account Record:' + updateAccountList[recordid].id + ', ' + err.getErrors()[0].getMessage() ;
                    errorLogList.add(new Error_log__c(Error_Level__c = 'High',Code_Type__c= 'execute',Snippet_Name__c= 'AccEntcountbatch',User_Name__c= 'Admin',Object_Name__c='Account',Error_Description__c=errormsgs));
                    
                }
                recordid ++;
            }
                                                
        }//End try
        catch(Exception e)
        {
           System.debug('****** errorLogList '+ errorLogList);
            
            //throw e;
        }
                     
                     
        if(errorLogList.size() > 0)
        {
            Insert errorLogList;
            Entitlement_batch__c ent = Entitlement_batch__c.getValues('status');
            ent.value__c='fail';
            update ent;
             
        }
       else
         {
           Entitlement_batch__c ent = Entitlement_batch__c.getValues('status');
            ent.value__c='success';
            update ent;
         }
    }//End execute method 

    
    global void finish(Database.BatchableContext info)
    {   
    	
          String st = Entitlement_batch__c.getValues('status').Value__c; 
          if (st!='fail') 
                {
                  updateBatchDate();
                  Entitlement_batch__c ent = Entitlement_batch__c.getValues('status');
                  ent.value__c='success'; 
                  update ent;
                }
    }//End finish method 
         
     
     // Increasing custom setting date so that job will pickup Entitlement records last modified date given by custom settings :  Entitlement batch
     public static void updateBatchDate() 
     {
        Entitlement_batch__c ent = Entitlement_batch__c.getValues('GRBatchDate');
        jobdate = Entitlement_batch__c.getValues('GRBatchDate').Value__c;
        
            Datetime temp = Date.today();
            System.debug('before updating date ***********'+temp);
            Datetime jobdate1 = temp.AddDays(1);
            String st2 = jobdate1.format('MM/dd/yyyy');
            System.debug('updating date ***********'+st2);
            ent.Value__c = st2;
      
        update ent;
    }//End updateBatchDate method
          
}