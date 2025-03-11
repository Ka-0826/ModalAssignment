@isTest
private class OpportunityLineItemControllerTest {
    
    @testSetup
    static void setupTestData() {

        // 価格表作成
        Pricebook__c pricebook = new Pricebook__c(Name = 'Test Pricebook');
        insert pricebook;

        // アカウント作成
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 商談作成
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), Pricebook__c = pricebook.Id, AccountId = acc.Id);
        insert opp;
        
        // グローバル選択リストの有効な値を取得
        List<Schema.PicklistEntry> category1Values = Schema.getGlobalDescribe().get('PricebookEntryMaster__c').getDescribe().fields.getMap().get('Category1__c').getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> category2Values = Schema.getGlobalDescribe().get('PricebookEntryMaster__c').getDescribe().fields.getMap().get('Category2__c').getDescribe().getPicklistValues();
        
        // デフォルト値を取得
        String validCategory1 = category1Values.isEmpty() ? null : category1Values[0].getValue();
        String validCategory2 = category2Values.isEmpty() ? null : category2Values[0].getValue();

        // 商品作成
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Category1__c = validCategory1,
            Category2__c = validCategory2
        );
        insert product;
        
        // 価格表エントリ作成
        PricebookEntryMaster__c pricebookEntry1 = new PricebookEntryMaster__c(
            Pricebook__c = pricebook.Id,
            Product2__c = product.Id,
            IsActive__c = true,
            CostPrice__c = 100,
            UnitPrice__c = 200,
            Category1__c = validCategory1,
            Category2__c = validCategory2
        );
        insert pricebookEntry1;

        PricebookEntryMaster__c pricebookEntry2 = new PricebookEntryMaster__c(
            Pricebook__c = pricebook.Id,
            Product2__c = product.Id,
            IsActive__c = true,
            CostPrice__c = -100,
            UnitPrice__c = -200,
            Category1__c = validCategory1,
            Category2__c = validCategory2
        );
        insert pricebookEntry2;
    }

    @isTest
    static void testGetOpportunityPricebookEntries() {

        Opportunity opp = [SELECT Id, Pricebook__c FROM Opportunity LIMIT 1];
        Pricebook__c pricebook = [SELECT Id FROM Pricebook__c LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> result = OpportunityLineItemController.GetOpportunityPricebookEntries(opp.Id, pricebook.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), '価格表エントリが返されるべき');
    }

    @isTest
    static void testGetOpportunityHelper() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Map<String, Id> result = OpportunityLineItemController.getOpportunityHelper(opp.Id);
        Test.stopTest();
        
        System.assert(result.containsKey('pricebookId'));
    }

    @isTest
    static void testGetOpportunityHelper_MissingOpportunity() {
        try {
            Test.startTest();
            OpportunityLineItemController.getOpportunityHelper(null);
            Test.stopTest();
            System.assert(false, '例外がスローされるべき');
        } catch (AuraHandledException e) {
            System.assert(true, '期待通りの例外が発生');
        } catch (Exception e) {
            System.assert(false, '予期しない例外が発生: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetOpportunityHelper_InvalidOpportunity() {

        Opportunity invalidOpportunity = new Opportunity(
            Name = 'Invalid Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Pricebook__c = null
        );
        insert invalidOpportunity;

        Test.startTest();
        try {
            OpportunityLineItemController.getOpportunityHelper(invalidOpportunity.Id);
            System.assert(false, '例外がスローされるべき');
        } catch (AuraHandledException e) {
            System.assert(true, '期待通りの例外が発生');
        } catch (Exception e) {
            System.assert(false, '予期しない例外が発生: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCategoryOptions() {
        Test.startTest();
        Map<String, List<String>> result = OpportunityLineItemController.getCategoryOptions();
        Test.stopTest();
        
        System.assert(result.containsKey('category1'));
        System.assert(result.containsKey('category2'));
        System.assert(result.get('category1').size() > 0, 'category1が取得されていない');
        System.assert(result.get('category2').size() > 0, 'category2が取得されていない');
    }

    @isTest
    static void testCreateLineItems() {

        Opportunity Opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntryMaster__c pricebookEntry = [SELECT Id, Product2__c FROM PricebookEntryMaster__c LIMIT 1];
        
        List<OpportunityLineItemMaster__c> lineItems = new List<OpportunityLineItemMaster__c>{
            new OpportunityLineItemMaster__c(
                Opportunity__c = opp.Id,
                Product2__c = pricebookEntry.Product2__c,
                Quantity__c = 1,
                CostPrice__c = 100,
                UnitPrice__c = 200
                )
        };
        
        Test.startTest();
        List<OpportunityLineItemMaster__c> result = OpportunityLineItemController.createLineItems(lineItems);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), '1 つの商談商品が作成されるべき');
    }

    @isTest
    static void testCreateLineItems_NullOrEmptyList() {
        List<OpportunityLineItemMaster__c> emptyList = new List<OpportunityLineItemMaster__c>();
        
        // null の場合と空リストの場合の両方をテスト
        List<List<OpportunityLineItemMaster__c>> testCases = new List<List<OpportunityLineItemMaster__c>>{null, emptyList};

        Test.startTest();

        for (List<OpportunityLineItemMaster__c> testCase : testCases) {
            try {  
                OpportunityLineItemController.createLineItems(testCase);
                System.assert(false, '例外がスローされるべき');
            } catch (AuraHandledException e) {
                System.assert(true, '期待通りの例外が発生');
            } catch (Exception e) {
                System.assert(false, '予期しない例外が発生: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateLineItems_InvalidData() {
        // 必要なデータを取得
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntryMaster__c pricebookEntry1 = [SELECT Id, Product2__c FROM PricebookEntryMaster__c WHERE CostPrice__c > 0 LIMIT 1];
        PricebookEntryMaster__c pricebookEntry2 = [SELECT Id, Product2__c FROM PricebookEntryMaster__c WHERE CostPrice__c < 0 LIMIT 1];

        // 正常なデータ
        OpportunityLineItemMaster__c lineItem1 = new OpportunityLineItemMaster__c(
            Opportunity__c = opp.Id,
            Product2__c = pricebookEntry1.Product2__c,
            CostPrice__c = 100,
            UnitPrice__c = 200,
            Quantity__c = 2
        );

         // 不正なデータ（必須項目が欠けている、または無効な値）
         OpportunityLineItemMaster__c lineItem2 = new OpportunityLineItemMaster__c(
            Opportunity__c = opp.Id,
            UnitPrice__c = -200
         );

        Test.startTest();
        List<OpportunityLineItemMaster__c> results1 = OpportunityLineItemController.createLineItems(new List<OpportunityLineItemMaster__c>{lineItem1});
        List<OpportunityLineItemMaster__c> results2 = OpportunityLineItemController.createLineItems(new List<OpportunityLineItemMaster__c>{lineItem2});
        Test.stopTest();

        // 結果確認: 成功したレコード数が1で、失敗したレコード数が1であることを確認
        System.assertEquals(1, results1.size(), '正常なデータのレコードが結果に含まれています。');
        System.assertEquals(1, results2.size(), '不正なデータのレコードが結果に含まれています。');
    }

    @isTest
    static void testCreateLineItems_TriggerException() {
        Test.startTest();
        try {
            // 完全に不正なデータを作成（必須項目なし）
            List<OpportunityLineItemMaster__c> invalidData = new List<OpportunityLineItemMaster__c>{
                new OpportunityLineItemMaster__c()
            };
            
            OpportunityLineItemController.createLineItems(invalidData);
            System.assert(false, '例外がスローされるべき');
        } catch (Exception e) {
            String errorMessage = e.getMessage();
            Boolean isExpectedException = errorMessage.contains('商談商品の作成中にエラーが発生しました。') || errorMessage.contains('Script-thrown exception');

            System.assert(isExpectedException, '予期しない例外が発生: ' + errorMessage);
        }
        Test.stopTest();
    }
}
