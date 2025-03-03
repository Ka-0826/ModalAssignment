@isTest
private class QuoteLineItemControllerTest {
    @testSetup
    static void setupTestData() {
        // 価格表作成
        Pricebook__c pricebook = new Pricebook__c(Name = 'Test Pricebook');
        insert pricebook;

        // アカウント作成
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today(), Pricebook__c = pricebook.Id, AccountId = acc.Id);
        insert opp;
        
        // 見積作成
        Quote__c quote = new Quote__c(Name = 'Test Quote', Opportunity__c = opp.Id);
        insert quote;
        
        // グローバル選択リストの有効な値を取得
        List<Schema.PicklistEntry> category1Values = Schema.getGlobalDescribe().get('PricebookEntryMaster__c').getDescribe().fields.getMap().get('Category1__c').getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> category2Values = Schema.getGlobalDescribe().get('PricebookEntryMaster__c').getDescribe().fields.getMap().get('Category2__c').getDescribe().getPicklistValues();
        
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
    static void testGetQuotePricebookEntries() {
        Quote__c quote = [SELECT Id, Opportunity__c FROM Quote__c LIMIT 1];
        Opportunity opp = [SELECT Id, Pricebook__c FROM Opportunity WHERE Id = :quote.Opportunity__c LIMIT 1];
        Pricebook__c pricebook = [SELECT Id FROM Pricebook__c LIMIT 1];
        
        Test.startTest();
        List<Map<String, Object>> result = QuoteLineItemController.getQuotePricebookEntries(quote.Id, opp.Id, pricebook.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, result.size(), '価格表エントリが返されるべき');
    }
    
    @isTest
    static void testGetQuoteHelper() {
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        
        Test.startTest();
        Map<String, Id> result = QuoteLineItemController.getQuoteHelper(quote.Id);
        Test.stopTest();
        
        System.assert(result.containsKey('opportunityId'));
        System.assert(result.containsKey('pricebookId'));
    }

    @isTest
    static void testGetQuoteHelper_MissingQuote() {
        try {
            Test.startTest();
            QuoteLineItemController.getQuoteHelper(null);
            Test.stopTest();
            System.assert(false, '例外がスローされるべき');
        } catch (AuraHandledException e) {
            System.assert(true, '期待通りの例外が発生');
        } catch (Exception e) {
            System.assert(false, '予期しない例外が発生: ' + e.getMessage());
        }
    }

    @isTest
    static void testGetQuoteHelper_InvalidQuote() {
        Quote__c invalidQuote = new Quote__c(Name = 'Invalid Quote', Opportunity__c = null);
        insert invalidQuote;

        Opportunity invalidOpportunity = new Opportunity(
            Name = 'Invalid Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Pricebook__c = null
        );
        insert invalidOpportunity;

        Quote__c quoteWithInvalidOpportunity = new Quote__c(
            Name = 'Quote with Invalid Opportunity',
            Opportunity__c = invalidOpportunity.Id
        );
        insert quoteWithInvalidOpportunity;

        Test.startTest();
        try {
            QuoteLineItemController.getQuoteHelper(invalidQuote.Id);
            System.assert(false, '例外がスローされるべき');
        } catch (AuraHandledException e) {
            System.assert(true, '期待通りの例外が発生');
        } catch (Exception e) {
            System.assert(false, '予期しない例外が発生: ' + e.getMessage());
        }

        try {
            QuoteLineItemController.getQuoteHelper(quoteWithInvalidOpportunity.Id);
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
        Map<String, List<String>> result = QuoteLineItemController.getCategoryOptions();
        Test.stopTest();
        
        System.assert(result.containsKey('category1'));
        System.assert(result.containsKey('category2'));
        System.assert(result.get('category1').size() > 0, 'category1が取得されていない');
        System.assert(result.get('category2').size() > 0, 'category2が取得されていない');
    }
    
    @isTest
    static void testCreateLineItems() {
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        PricebookEntryMaster__c pricebookEntry = [SELECT Id, Product2__c FROM PricebookEntryMaster__c LIMIT 1];
        
        List<QuoteLineItemMaster__c> lineItems = new List<QuoteLineItemMaster__c>{
            new QuoteLineItemMaster__c(Quote__c = quote.Id, Product2__c = pricebookEntry.Product2__c, Quantity__c = 1, CostPrice__c = 100, UnitPrice__c = 200)
        };
        
        Test.startTest();
        List<QuoteLineItemMaster__c> result = QuoteLineItemController.createLineItems(lineItems);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), '1 つの見積品目が作成されるべき');
    }

    @isTest
    static void testCreateLineItems_NullOrEmptyList() {
        List<QuoteLineItemMaster__c> emptyList = new List<QuoteLineItemMaster__c>();
        
        // null の場合と空リストの場合の両方をテスト
        List<List<QuoteLineItemMaster__c>> testCases = new List<List<QuoteLineItemMaster__c>>{null, emptyList};

        Test.startTest();

        for (List<QuoteLineItemMaster__c> testCase : testCases) {
            try {  
                QuoteLineItemController.createLineItems(testCase);
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
        Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
        PricebookEntryMaster__c pricebookEntry1 = [SELECT Id, Product2__c FROM PricebookEntryMaster__c WHERE CostPrice__c > 0 LIMIT 1];
        PricebookEntryMaster__c pricebookEntry2 = [SELECT Id, Product2__c FROM PricebookEntryMaster__c WHERE CostPrice__c < 0 LIMIT 1];

        // 正常なデータ
        QuoteLineItemMaster__c lineItem1 = new QuoteLineItemMaster__c(
            Quote__c = quote.Id,
                Product2__c = pricebookEntry1.Product2__c,
                CostPrice__c = 100,
                UnitPrice__c = 200,
                Quantity__c = 2
        );

         // 不正なデータ（必須項目が欠けている、または無効な値）
         QuoteLineItemMaster__c lineItem2 = new QuoteLineItemMaster__c(
            Quote__c = quote.Id,
            UnitPrice__c = -200
         );

        Test.startTest();
        List<QuoteLineItemMaster__c> results1 = QuoteLineItemController.createLineItems(new List<QuoteLineItemMaster__c>{lineItem1});
        List<QuoteLineItemMaster__c> results2 = QuoteLineItemController.createLineItems(new List<QuoteLineItemMaster__c>{lineItem2});
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
            List<QuoteLineItemMaster__c> invalidData = new List<QuoteLineItemMaster__c>{
                new QuoteLineItemMaster__c()
            };
            
            QuoteLineItemController.createLineItems(invalidData);
            System.assert(false, '例外がスローされるべき');
        } catch (Exception e) {
            String errorMessage = e.getMessage();
            Boolean isExpectedException = errorMessage.contains('見積品目の作成中にエラーが発生しました。') || errorMessage.contains('Script-thrown exception');

            System.assert(isExpectedException, '予期しない例外が発生: ' + errorMessage);
        }
        Test.stopTest();
    }
}
