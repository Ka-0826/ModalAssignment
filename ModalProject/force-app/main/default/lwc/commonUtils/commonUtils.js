import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export function showToast(title, message, variant = 'success') {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    return event;
}