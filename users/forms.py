from django import forms

# Form for user login
class LoginForm(forms.Form):
    email = forms.EmailField(max_length=100, label="Email")
    password = forms.CharField(widget=forms.PasswordInput, label="Password")
    user_type = forms.ChoiceField(choices=[('customer', 'Customer'), ('restaurant', 'Restaurant'), ('agent', 'Agent')])

# Form for user signup
class SignupForm(forms.Form):
    user_id = forms.CharField(max_length = 20,label="user_id")
    email = forms.EmailField(max_length=100, label="Email")
    password = forms.CharField(widget=forms.PasswordInput, label="Password")
    phone_number = forms.CharField(max_length=10, label="Phone Number")
    name = forms.CharField(max_length=100, label="Name")
    user_type = forms.ChoiceField(choices=[('customer', 'Customer'), ('restaurant', 'Restaurant'), ('agent', 'Agent')])


class AddressForm(forms.Form):
    streetline_1 = forms.CharField(
        label="Street Line 1",
        max_length=255,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Street Line 1', 'class': 'form-control'}),
    )
    streetline_2 = forms.CharField(
        label="Street Line 2 (Optional)",
        max_length=255,
        required=False,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Street Line 2', 'class': 'form-control'})
    )
    city = forms.CharField(
        label="City",
        max_length=100,
        widget=forms.TextInput(attrs={'placeholder': 'Enter City', 'class': 'form-control'})
    )
    state = forms.CharField(
        label="State",
        max_length=100,
        widget=forms.TextInput(attrs={'placeholder': 'Enter State', 'class': 'form-control'})
    )
    country = forms.CharField(
        label="Country",
        max_length=100,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Country', 'class': 'form-control'})
    )
    zipcode = forms.CharField(
        label="Zipcode",
        max_length=10,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Zipcode', 'class': 'form-control'})
    )

class CustomerProfileForm(forms.Form):
    date_of_birth = forms.DateField(
        widget=forms.DateInput(attrs={'type': 'date'}), 
        label="Date of Birth"
    )
    gender = forms.ChoiceField(
        choices=[('Male', 'Male'), ('Female', 'Female'), ('Others', 'Others')],
        label="Gender"
    )
    membership_type = forms.ChoiceField(
        choices=[('General', 'General'), ('Premium', 'Premium')],
        label="Membership Type"
    )


class RestaurantProfileForm(forms.Form):
    category = forms.CharField(max_length=50, label="Category", required=False)



class DeliveryAgentProfileForm(forms.Form):
    year_of_joining = forms.IntegerField(
        widget=forms.NumberInput(attrs={'placeholder': 'Year of Joining'}),
        label="Year of Joining"
    )
    gender = forms.ChoiceField(
        choices=[
            ('Male', 'Male'),
            ('Female', 'Female'),
            ('Others', 'Others')
        ],
        label="Gender"
    )
    age = forms.IntegerField(
        widget=forms.NumberInput(attrs={'placeholder': 'Age'}),
        label="Age",
        min_value=18,
        max_value=65
    )
    license_number = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={'placeholder': 'Enter License Number'}),
        label="License Number"
    )



class VehicleForm(forms.Form):
    vehicle_number = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Vehicle Number'}),
        label="Vehicle Number"
    )
    v_type = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Vehicle Type'}),
        label="Vehicle Type"
    )
    v_color = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Vehicle Color'}),
        label="Vehicle Color"
    )
    vehicle_registration_number = forms.CharField(
        max_length=50,
        widget=forms.TextInput(attrs={'placeholder': 'Enter Registration Number'}),
        label="Vehicle Registration Number"
    )
