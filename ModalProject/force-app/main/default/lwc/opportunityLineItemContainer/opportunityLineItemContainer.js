import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { showToast } from 'c/commonUtils';
import createLineItems from '@salesforce/apex/OpportunityLineItemController.createLineItems';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class OpportunityLineItemContainer extends LightningElement {
    @api recordId;                    // 見積レコードのID
    @track isFirstOpen = true;        // 商品選択画面
    @track isSecondOpen = false;      // 商品編集画面

    @api columns = [];                // 商品リスト
    @api hideCheckboxColumn = false;  // 画面のチェックボックス

    @api selectedProducts;            // 商品選択データ
    @track secondTableData = [];      // 編集用のデータ

    // クローズボタンの処理
    handleCloseModal() {
        console.log('モーダルが閉じられました');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        if (!this.recordId) {
            console.error('recordId が undefined です');
            return;
        }
        
        console.log('recordId:', this.recordId);
    }

    // 商品選択画面で「次へ」ボタンを押したときOpportunityProductSelectionを呼び出す処理
    handleNextFromChild(event) {
        if (!this.isFirstOpen) {
            console.error('c-opportunity-product-selection は現在表示されていません。');
            return;
        }
    
        const productSelection = this.template.querySelector('c-opportunity-product-selection');
    
        if (!productSelection) {
            console.error('c-opportunity-product-selection が見つかりません。');
            return;
        }
    
        productSelection.handleNext(event);
    }

    // OpportunityProductSelectionから受け取った処理
    handleNext(event) {
        console.log('next clicked');
        // 配列をコピー
        this.selectedProducts = [...event.detail];
        this.isFirstOpen = false;
        this.isSecondOpen = true;
        this.hideCheckboxColumn1 = true;
        this.hideCheckboxColumn2 = true;

        // 選択された商品を secondTableData に渡す
        this.secondTableData = [...this.selectedProducts];
    }

    // 商品編集画面で「保存」ボタンを押したときproductEditorを呼び出す処理
    handleSaveFromChild(event) {
        if (!this.isSecondOpen) {
            console.error('c-opportunity-product-editor は現在表示されていません。');
            return;
        }
    
        const productEditor = this.template.querySelector('c-opportunity-product-editor');
    
        if (!productEditor) {
            console.error('c-opportunity-product-editor が見つかりません。');
            return;
        }
        productEditor.handleSave(event);
    }

    // OpportunityProductEditorから受け取った処理
    handleSave(event) {
        // 配列をコピー
        this.secondTableData = [...event.detail];

        if (!Array.isArray(this.secondTableData) || this.secondTableData.length === 0) {
            this.dispatchEvent(showToast('警告', '商品を選択してください。', 'warning'));
            return;
        }

        // Apexへ送るデータ整形
        const finalData = this.secondTableData.map(item => ({
            Opportunity__c: this.recordId,
            Product2__c: item.ProductId,
            Name: '商談商品 ' + item.Name,
            Quantity__c: item.Quantity || 1,
            CostPrice__c: item.CostPrice,
            UnitPrice__c: item.UnitPrice,
            Discount__c: item.Discount || null,
        }));

        createLineItems({ finalData })
            .then(() => {
                this.dispatchEvent(showToast('成功', '商談商品が作成されました。', 'success'));

                // UI の標準関連リストを更新
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

                // モーダルを閉じる
                this.dispatchEvent(new CloseActionScreenEvent());

                // 編集データをクリア
                this.secondTableData = [];

                // 子コンポーネントを取得・データ更新
                setTimeout(() => {
                    const productEditor = this.template.querySelector('c-opportunityーproduct-editor');
                    if (OpportunityProductEditor) {
                        OpportunityProductEditor.refreshData();
                    } else {
                        console.error('OpportunityProductEditor が見つかりませんでした。');
                    }
                }, 100); 
            })
            .catch(error => {
                console.error('保存エラー:', error);
                this.dispatchEvent(showToast('エラー', '商談商品の作成に失敗しました。', 'error'));
            });
    }
}
