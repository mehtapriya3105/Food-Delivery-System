// Toggle edit mode for phone number
function toggleEdit() {
    var phoneField = document.getElementById('phone_number');
    var submitButton = document.getElementById('submit');
    
    if (phoneField.readOnly) {
        phoneField.readOnly = false;
        phoneField.classList.add('editable');
        submitButton.style.display = 'inline';  // Show the save button
    } else {
        phoneField.readOnly = true;
        phoneField.classList.remove('editable');
        submitButton.style.display = 'none';  // Hide the save button
    }
}
