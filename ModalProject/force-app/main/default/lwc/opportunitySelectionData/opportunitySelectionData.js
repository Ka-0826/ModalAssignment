import { LightningElement, api, track, wire } from 'lwc';
import getOpportunityPricebookEntries from '@salesforce/apex/OpportunityLineItemController.getOpportunityPricebookEntries';
import getOpportunityHelper from '@salesforce/apex/OpportunityLineItemController.getOpportunityHelper';
import getCategoryOptions from '@salesforce/apex/QuoteLineItemController.getCategoryOptions';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

const OPPORTUNITY_FIELDS = ['Opportunity.Id'];

export default class OpportunitySelectionData extends LightningElement {
    @api recordId;                                   // レコードID
    @api get gridData() { return this._gridData; }   // 外部から _gridData を取得するためのメソッド
    @track opportunityId;                            // 商談レコードのID
    @track pricebookId;                              // 価格表マスタレコードのID
    _gridData = [];                                  // 内部データ格納用の配列
    _options1 = [];                                  // 商品分類1を格納する配列
    _options2 = [];                                  // 商品分類2を格納する配列
    wiredQuoteResult;                                // refreshApex 用の変数
    
    @wire(getRecord, { recordId: '$recordId', fields: OPPORTUNITY_FIELDS })
    wiredOpportunity(result) {
        this.wiredOpportunityResult = result; // refreshApex の対象として保存
        const { data, error } = result;

        if (data) {

            this.opportunityId = data.fields?.Id?.value;

            if (this.opportunityId) {
                this.loadProducts();
                this.loadCategoryOptions();
            }
        } else if (error) {
            console.error('データの取得に失敗しました。', error);
        }
    }

    //商品リストの取得
    async loadProducts() {
        if (!this.opportunityId) {
            console.error('opportunityId が未取得のため、商品リストの取得をスキップ');
            return;
        }

        try {

            // 商談Id、価格表マスタIdを取得
            const dependencies = await getOpportunityHelper({ opportunityId: this.opportunityId });
            if (!dependencies || !dependencies.pricebookId) {
                console.error('価格表の取得に失敗:', dependencies);

                return;
            }

            this.pricebookId = dependencies.pricebookId;

            // 価格表エントリを取得
            const data = await getOpportunityPricebookEntries({
                opportunityId: this.opportunityId,
                pricebookId: this.pricebookId
            });
            
            if (!data || !Array.isArray(data)) {
                console.error('価格表エントリの取得結果が不正:', data);

                return;
            }
            
            this.gridData = data.map(item => ({
                Id: item.Id,
                ProductId: item.Product2__c,
                Name: item.ProductName || '',
                ProductCode: item.ProductCode__c || '',
                IsActive: item.IsActive__c,
                CostPrice: item.CostPrice__c,
                UnitPrice: item.UnitPrice__c,
                Category1: item.Category1__c,
                Category2: item.Category2__c
            }));

        } catch (error) {
            console.error('商品データの取得エラー:', error);
        }
    }

    // 商品分類の取得
    async loadCategoryOptions() {
        try {
            const data = await getCategoryOptions();
            if (!data || !data.category1 || !data.category2) {
                throw new Error('商品分類データの取得に失敗しました。');
            }
            this.options1 = data.category1.map(value => ({ label: value, value }));
            this.options2 = data.category2.map(value => ({ label: value, value }));
        } catch (error) {
            console.error('商品分類の取得エラー:', error);
        }
    }

    get gridData() {
        return this._gridData;
    }

    get options1() {
        return this._options1;
    }

    get options2() {
        return this._options2;
    }

    set gridData(value) {
        this._gridData = [...value]; 
        this.dispatchEvent(new CustomEvent('gridupdate', { detail: this._gridData }));
    }

    set options1(value) {
        this._options1 = [...value]; 
    }
    
    set options2(value) {
        this._options2 = [...value]; 
    }

    // データのリフレッシュ
    @api
    refreshData() {
        return refreshApex(this.wiredOpportunityIdResult)// データを最新化
            .then(() => {
                return this.loadProducts(); // 最新化後の商品データを取得
            })
            .catch(error => {
                console.error('refreshData() エラー:', error);
            });
    }
}