from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.db import connection
from .forms import *
import json
import datetime
from .db_utils import execute_query 
from django.http import HttpResponseRedirect
from django.urls import reverse
from django.contrib import messages
# Genral Signup View Page 1
def user_signup_view(request):
    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            userid = form.cleaned_data['user_id']
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            phone_number = form.cleaned_data['phone_number']
            name = form.cleaned_data['name']
            user_type = form.cleaned_data['user_type']
            request.session['temp_user_data'] = {
                'user_id': userid,
                'email': email,
                'password': password,
                'phone_number': phone_number,
                'name': name,
                'user_type': user_type,
            }
            print("hello")
            if(user_type == "customer"):
                return HttpResponseRedirect(reverse('signup_extended'))
            elif(user_type == "restaurant"):
                return HttpResponseRedirect(reverse('restro_extended'))
            elif(user_type == "agent"):
                return HttpResponseRedirect(reverse("agent_extended"))
    else:
        form = SignupForm()
    return render(request, 'signup.html', {'form': form})

#Sign up for the delivery agent-Page 3
def get_agent_login_extended(request):
    if request.method == 'POST':
        form = DeliveryAgentProfileForm(request.POST)
        if form.is_valid():
            user_data = request.session.get('temp_user_data')
            if not user_data:
                return redirect('signup')
            user_data.update({
                'year_of_joining': form.cleaned_data['year_of_joining'],
                'gender': form.cleaned_data['gender'],
                'age': form.cleaned_data['age'],
                'license_number' : form.cleaned_data['license_number']
            })
            request.session['agent_user_data'] = user_data 
            return HttpResponseRedirect(reverse('vehicle_details'))
    else:
        form = DeliveryAgentProfileForm()
    return render(request, 'delivery_agent_signup_extended.html', {'form': form})

#Signup for the delivery agent-Page 3
def get_new_agent_vehicle_details(request):
    if request.method == 'POST':
        form = VehicleForm(request.POST)
        if form.is_valid():
            vehicle_number = form.cleaned_data['vehicle_number']
            v_type = form.cleaned_data['v_type']
            v_color = form.cleaned_data['v_color']
            vehicle_registration_number = form.cleaned_data['vehicle_registration_number']
            agent_user_data = request.session.get('agent_user_data')
            if not agent_user_data:
                return redirect('signup')
            userid = agent_user_data.get('user_id')
            password = agent_user_data.get('password')
            email = agent_user_data.get('email')
            phone_number = agent_user_data.get('phone_number')
            name = agent_user_data.get('name')
            year_of_joining = agent_user_data.get('year_of_joining')
            gender = agent_user_data.get('gender')
            age = agent_user_data.get('age')
            license_number = agent_user_data.get('license_number')
            message = ""
            with connection.cursor() as cursor:
                message = cursor.callproc('RegisterAgent', [
                    userid, password, email, phone_number, name,
                     'agent',vehicle_number,v_type,v_color,
                    vehicle_registration_number,userid,year_of_joining,gender,age,license_number,
                    message
                ])
            del request.session['agent_user_data']
            return redirect('login')
    else:
        form = VehicleForm()
    return render(request, 'vehicle_data.html', {'form': form})

#Sign Up page for the restaurant 2
def restaurant_signup_view_extended(request):
    if request.method == 'POST':
        form = RestaurantProfileForm(request.POST)
        if form.is_valid():
            user_data = request.session.get('temp_user_data')
            if not user_data:
                return redirect('signup')
            user_data.update({
                'category': form.cleaned_data['category']
            })
            request.session['temp_user_data'] = user_data 
            return HttpResponseRedirect(reverse('restro_address'))
    else:
        form = RestaurantProfileForm()

    return render(request, 'restaurant_signup.html', {'form': form})


#Signup page for the restaurant 3
def get_new_restaurant_address(request):
    if request.method == 'POST':
        form = AddressForm(request.POST)
        if form.is_valid():
            streetline_1 = form.cleaned_data['streetline_1']
            streetline_2 = form.cleaned_data['streetline_2']
            city = form.cleaned_data['city']
            state = form.cleaned_data['state']
            country = form.cleaned_data['country']
            zipcode = form.cleaned_data['zipcode']
            restaurant_data = request.session.get('temp_user_data')
            if not restaurant_data:
                return redirect('signup')
            userid = restaurant_data.get('user_id')
            password = restaurant_data.get('password')
            email = restaurant_data.get('email')
            phone_number = restaurant_data.get('phone_number')
            name = restaurant_data.get('name')
            category = restaurant_data.get('category')
            with connection.cursor() as cursor:
                cursor.callproc('RegisterRestaurant', [
                    userid, password, email, phone_number, name,
                    datetime.datetime.now(), datetime.datetime.now(), 'restaurant',
                    streetline_1, streetline_2, city, state, country, zipcode, category
                ])
            del request.session['temp_user_data']
            return redirect('login')
    else:
        form = AddressForm()
    return render(request, 'newUserAddress.html', {'form': form})


def user_signup_view_extended(request):
    if request.method == 'POST':
        form = CustomerProfileForm(request.POST)
        if form.is_valid():
            date_of_birth = form.cleaned_data['date_of_birth']
            gender = form.cleaned_data['gender']
            membership_type = form.cleaned_data['membership_type']
            user_data = request.session.get('temp_user_data')
            if not user_data:
                return redirect('signup')
            user_data.update({
                'date_of_birth': date_of_birth.isoformat(),
                'gender': gender,
                'membership_type': membership_type,
            })
            request.session['temp_user_data'] = user_data  
            return HttpResponseRedirect(reverse('get_new_user_address'))
    else:
        form = CustomerProfileForm()

    return render(request, 'signup_extended.html', {'form': form})

    
def get_new_user_address(request):
    if request.method == 'POST':
        form = AddressForm(request.POST)
        if form.is_valid():
            streetline_1 = form.cleaned_data['streetline_1']
            streetline_2 = form.cleaned_data['streetline_2']
            city = form.cleaned_data['city']
            state = form.cleaned_data['state']
            country = form.cleaned_data['country']
            zipcode = form.cleaned_data['zipcode']
            user_data = request.session.get('temp_user_data')
            if not user_data:
                return redirect('signup')
            userid = user_data.get('user_id')
            password = user_data.get('password')
            email = user_data.get('email')
            phone_number = user_data.get('phone_number')
            name = user_data.get('name')
            user_type = user_data.get('user_type')
            user_data = request.session.get('temp_user_data')
            date_of_birth = user_data.get('date_of_birth')
            gender = user_data.get('gender')
            membership_type = user_data.get('membership_type')
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('RegisterCustomerWithAddress', [
                        userid, password, email, phone_number, name,date_of_birth,gender,membership_type,streetline_1,streetline_2,city,state,country,zipcode
                    ])
                del request.session['temp_user_data']
                messages.success(request, 'Signup successful!')
                print(messages)
                return render(request, 'newUserAddress.html', {'form': form})
            except Exception as e:
                messages.error(request, f"Signup failed.\n Error: {str(e)}")
                return render(request, 'newUserAddress.html', {'form': form})
    else:
        
        form = AddressForm()
    return render(request, 'newUserAddress.html', {'form': form})



# Function to execute login and return user details (for simplicity, assuming it's part of the same query)
def execute_login_function(email, password, user_type):
    query = """
    SELECT UserLoginFn(%s,%s,%s);
    """
    return execute_query(query, (email,password, user_type))

# Login view
def login_view(request):
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            user_type = form.cleaned_data['user_type']
            result = execute_login_function(email, password, user_type)
            
            try:
                result = json.loads(result[0])  
                print(result)
            except json.JSONDecodeError:
                return render(request, 'login.html', {'form': form, 'error': 'Error parsing login result'})
            
            if(result['message'] == "Invalid credentials"):
                messages.error(request, "Invalid Credentials.")
                return render(request, 'login.html', {'form': form})
            else:
                request.session['user_id'] = result['user_id']
                request.session['user_type'] = result['user_type']
                if result['user_type'] == 'customer':
                    try:
                        messages.success(request, 'Customer login successful!')
                        return render(request, 'login.html', {'form': form})
                    except Exception as e:
                        messages.error(request, f"Customer Login failed.\n Error: {str(e)}")
                        return render(request, 'login.html', {'form': form})
                elif result['user_type'] == 'restaurant':
                    try:
                        messages.success(request, 'Restaurant Login successful!')
                        return render(request, 'login.html', {'form': form})
                    except Exception as e:
                        messages.error(request, f"Restaurant Login failed.\n Error: {str(e)}")
                        return render(request, 'login.html', {'form': form})
                elif result['user_type'] == 'agent':
                    try:
                        messages.success(request, 'Agent Login successful!')
                        return render(request, 'login.html', {'form': form})
                    except Exception as e:
                        messages.error(request, f"Agent Login failed.\n Error: {str(e)}")
                        return render(request, 'login.html', {'form': form})
    else:
        form = LoginForm()
    
    return render(request, 'login.html', {'form': form})

# Function to get customer details using the stored user ID
def get_customer_details(user_id):
    query = """
    SELECT GetCustomerDetailsByUserID(%s);
    """
    return execute_query(query, (user_id,))

#this function fetches the food catagory options from all the restaurants
def get_food_categories():
    """Function to fetch the list of food categories from the SQL function."""
    with connection.cursor() as cursor:
        try:
            cursor.execute("SELECT get_food_categories()")  
            result = cursor.fetchone() 
            print("Food Categories:", result)  
            return result[0] if result else ""  
        except Exception as e:
            print("Error fetching food categories:", str(e))
            return ""

#This function fetched the restaurant details based on the restaurant id
def get_restaurant_details(user_id):
    query = """
    SELECT get_restaurant_details(%s);
    """
    return execute_query(query, (user_id,))

#This is the restaurant dashboard
def restaurant_dashboard_view(request):
    if 'user_id' not in request.session or request.session.get('user_type') != 'restaurant':
        return redirect('login') 
    user_id = request.session['user_id']
    try:
        # Fetch initial restaurant details
        result = get_restaurant_details(user_id)
        restaurant_details = json.loads(result[0]) 
        print(restaurant_details)
        print(restaurant_details['address_id'])
    except json.JSONDecodeError as e:
        print("JSON decode error:", e)
        return render(request, 'error.html', {'message': 'Error retrieving restaurant details'})

    if request.method == "POST":
        phone_number = request.POST.get("phone_number")

        streetline_1 = request.POST.get("streetline_1")
        streetline_2 = request.POST.get("streetline_2")
        city = request.POST.get("city")
        state = request.POST.get("state")
        country = request.POST.get("country")
        zipcode = request.POST.get("zipcode")
        try:
            with connection.cursor() as cursor:
                cursor.callproc('UpdateUserPhoneNumber', [user_id, phone_number])
                print( user_id, restaurant_details['address_id'], streetline_1, streetline_2, city, state, country, zipcode)
                cursor.callproc('UpdateCustomerAddress', [
                    user_id, restaurant_details['address_id'], streetline_1, streetline_2, city, state, country, zipcode])
                connection.commit()
        except Exception as e:
            print("Database update error:", e)
            return render(request, 'error.html', {'message': 'Failed to update details'})

        # Fetch the updated details
        try:
            result = get_restaurant_details(user_id)
            restaurant_details = json.loads(result[0])  
        except json.JSONDecodeError as e:
            print("JSON decode error after update:", e)
            return render(request, 'error.html', {'message': 'Error retrieving updated details'})

   
    return render(request, 'restaurant_dashboard.html', {
        'restaurant_details': restaurant_details,  
    })

#This is the customer dashboard
def customer_dashboard(request):
    if 'user_id' not in request.session:
        return redirect('login') 
    user_id = request.session['user_id']
    customer_details_json = get_customer_details(user_id)[0]
    customer_details = json.loads(customer_details_json)
    if request.method == "POST":
        phone_number = request.POST.get("phone_number")       
        with connection.cursor() as cursor:
            cursor.callproc('UpdateUserPhoneNumber', [user_id, phone_number])
            connection.commit()      
        customer_details_json = get_customer_details(user_id)[0]
        customer_details = json.loads(customer_details_json)
   
    food_categories = get_food_categories().split(',')  
    return render(request, 'customer_dashboard.html', {
        'customer_details': customer_details,  
        'food_categories': food_categories  
    })

#This function is used for the restaurant and the custoomer to edit the phone number
def edit_phone_number(request):
    if 'user_id' not in request.session:
        return redirect('login')
    user_id = request.session['user_id']
    if request.method == 'POST':
        new_phone_number = request.POST.get('phone_number')
        with connection.cursor() as cursor:
            try:
                cursor.callproc('UpdateUserPhoneNumber', [user_id, new_phone_number])
            except Exception as e:
                return render(request, 'edit_phone_number.html', {'error': str(e)})
        if('user_type' == 'customer'):
            return redirect('customer_dashboard')
        elif('user_type' == 'restaurant'):
            return redirect('restaurant_dashboard_view')
    return render(request, 'edit_phone_number.html')

#This function gets all the address of a given user
def address_book(request):
    if 'user_id' not in request.session:
        return redirect('login')  
    user_id = request.session['user_id']
    with connection.cursor() as cursor:
        cursor.execute("SELECT GetAllCustomerAddressesFn(%s);", [user_id])
        addresses = cursor.fetchall()  
    if addresses and addresses[0]:
        address_data = json.loads(addresses[0][0])  
    else:
        address_data = []

    if request.method == 'POST':
        action = request.POST.get('action')

        if action == 'insert':
            streetline_1 = request.POST.get('streetline_1')
            streetline_2 = request.POST.get('streetline_2', '')
            city = request.POST.get('city')
            state = request.POST.get('state')
            country = request.POST.get('country')
            zipcode = request.POST.get('zipcode')
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('InsertCustomerAddress', [
                        user_id, streetline_1, streetline_2, city, state, country, zipcode
                    ])
                messages.success(request, 'Insert successful')
            except Exception as e:
                messages.error(request, f"Insert Failure.\n Error: {str(e)}")
                  
        
        elif action == 'update':
            address_id = request.POST.get('address_id')
            streetline_1 = request.POST.get('streetline_1')
            streetline_2 = request.POST.get('streetline_2', '')
            city = request.POST.get('city')
            state = request.POST.get('state')
            country = request.POST.get('country')
            zipcode = request.POST.get('zipcode')
            try:
                with connection.cursor() as cursor:
                    cursor.callproc('UpdateCustomerAddress', [
                        user_id, address_id, streetline_1, streetline_2, city, state, country, zipcode
                    ])
                messages.success(request, 'Update successful')
            except Exception as e:
                messages.error(request, f"Update Failure.\n Error: {str(e)}")   
            
        return redirect('address_book')  

    food_categories = get_food_categories().split(',')  
    category_urls = [
        {
            'category_name': category,
            'url': f'/{category}/'  
        }
        for category in food_categories
    ]
    return render(request, 'address_book.html', {
        'addresses': address_data,  
        'category_urls': category_urls
    })



def delete_address(request):
    # Check if the request is a POST request and has JSON data
    if 'user_id' not in request.session:
        return redirect('login')  
    user_id = request.session['user_id']
    if request.method == 'POST':
        try:
            # Parse the JSON request body
            data = json.loads(request.body)
            action = data.get('action')
            address_ids = data.get('address_ids', [])

            if action == 'delete' and address_ids:
                with connection.cursor() as cursor:
                    for address_id in address_ids:
                        try:
                            # Assuming user_id is available (you can get it from session or request)
                            cursor.callproc('DeleteCustomerAddress', [user_id, address_id])
                            # If the delete is successful, return success message
                            messages.success(request, 'Delete successful')
                        
                        except Exception as e:
                            # Log error and send failure message
                            messages.error(request, f"Delete Failure. Error: {str(e)}")
                            return JsonResponse({"success": False, "error": f"Delete Failure. Error: {str(e)}"}, status=400)

                # If everything goes fine, return a success JSON response
                return JsonResponse({"success": True, "message": "Addresses deleted successfully"})
            
            else:
                return JsonResponse({"success": False, "error": "Invalid action or missing address IDs"}, status=400)

        except json.JSONDecodeError:
            return JsonResponse({"success": False, "error": "Invalid JSON request"}, status=400)

    # If the request method is not POST or content-type is not JSON
    return JsonResponse({"success": False, "error": "Invalid request method"}, status=400)



#This function gives the list of restaurant by a specific catagory
def restaurant_list_by_category(request, category):
    query = """
        SELECT GetRestaurantsByCategory(%s);
    """
    
    with connection.cursor() as cursor:
        cursor.execute(query, [category])
        rows = cursor.fetchall()   
    if rows:
        result_json = rows[0][0] 
        print(result_json)
        if(result_json== None):
            restaurants = {}
        else:
            restaurants = json.loads(result_json)  
    return render(request, 'restaurant_list.html', {
        'category': category,
        'restaurants': restaurants
    })

#This function fetches the menu of a particular user
def restaurant_menu(request, restaurant_id, category_name):
    query = """
        SELECT GetMenuByRestaurantAndCategory(%s, %s);
    """
    with connection.cursor() as cursor:
        cursor.execute(query, [restaurant_id, category_name])
        rows = cursor.fetchall()
    
    menu_data = []
    if rows:
        result_json = rows[0][0]
        menu_data = json.loads(result_json)  
        print()
    return render(request, 'restaurant_menu.html', {
        'restaurant_id': restaurant_id,
        'category_name': category_name,
        'menu_data': menu_data,
    })

#this function fetches the ingredients for a given item for the databased
def get_ingredients_for_item(request, restaurant_id, menu_id):
    ingredients_data = []

    if request.method == "POST":
        query = """
            SELECT GetIngredientsForRestaurantAndMenu(%s, %s);
        """
        with connection.cursor() as cursor:
            cursor.execute(query, [restaurant_id, menu_id])
            rows = cursor.fetchone()
            print(rows)
        if rows and rows[0][0]:
            result_json = rows[0][0]  
            print("Raw result:", result_json)  
            try:
               
                ingredients_data = json.loads(result_json)
                print("Parsed JSON:", ingredients_data)  
            except json.JSONDecodeError as e:
                print("Error decoding JSON:", e)
                ingredients_data = []  
        else:
            print("Query returned no data or result is empty.")
        print(ingredients_data)
    return render(request, 'ingredients_menu.html', {
        'restaurant_id': restaurant_id,
        'menu_id': menu_id,
        'ingredients_data': ingredients_data,
    })




#This funciton fetches the details of the restauran menu given the restaurant id, it also creates updates and deletes the menu items as needed
def restaurant_menu_for_restuarant_login(request):
    restaurant_id = request.session['user_id']
    
    if request.method == 'POST':
        action = request.POST.get('action')
        print("action: ", action)
        if action == 'insert':
            
            item_name = request.POST.get('item_name')
            item_description = request.POST.get('item_description')
            price = request.POST.get('price')
            availability = request.POST.get('availability')
            taste = request.POST.get('cuisine_taste') 
            country = request.POST.get('cuisine_country')  
            category = request.POST.get('cuisine_category')  
            menu_id = request.POST.get('menu_id')
            with connection.cursor() as cursor:
                cursor.callproc('AddMenuItem', [ restaurant_id, item_name, item_description, price, availability, taste, country, category])
            return JsonResponse({
                'success': True,
                'action' : "insert"
            })
        elif action == 'update':
            item_id = request.POST.get('item_id')
            item_description = request.POST.get('item_description')
            price = request.POST.get('price')
            availability = request.POST.get('availability')
            item_name = request.POST.get('item_name')
            with connection.cursor() as cursor:
                print([item_id, item_name,item_description, price, availability])
                cursor.callproc("UpdateMenuItem", 
                                [item_id, item_name,item_description, price, availability]
                )
            return JsonResponse({
                'success': True,
                'action' : "update"
            })


        elif action == "delete":
                menu_id = request.POST.get("menu_id")
                with connection.cursor() as cursor:
                        deletion_successful = True
                        deletion_successful = cursor.callproc("DeleteMenuItem", [restaurant_id, menu_id,deletion_successful])
                        return JsonResponse({
                            'success': True,
                        })
        return JsonResponse({'status': 'error', 'message': 'Invalid request'})
    with connection.cursor() as cursor:
        print(restaurant_id)
        cursor.execute("SELECT GetMenuByRestaurant(%s)", [restaurant_id])
        menu_items_json = cursor.fetchone()[0]  # Get JSON result
    menu_items = json.loads(menu_items_json) if menu_items_json else []
    print(menu_items)
    return render(request, 'restaurant_menu_view.html', {
        'menu_items': menu_items,
        'restaurant_id': restaurant_id
    })

#This function gets the order for a restuarant based on the status of i.e.: Cooking , Ready for Pickup and Delivered
def get_orders_by_status(request):
    restaurant_id = request.session.get('user_id')  
    with connection.cursor() as cursor:
        cursor.execute("SELECT GetOrdersByRestaurant(%s)", [restaurant_id])
        result = cursor.fetchone()[0] 
    orders = json.loads(result) if result else {}
    return render(request, 'orders_page.html', {
        'cooking_orders': orders.get('cooking', []),
        'delivered_orders': orders.get('delivered', []),
        'Ready_for_Pickup': orders.get('Ready for Pickup', [])
    })


# This function updates the status of cooking as stated by the restaurant 
def update_order_status(request):
    if request.method == 'POST':
        data = json.loads(request.body)  
        order_id = data.get('order_id')
        action = data.get('action')
        print(order_id,action)
        if action == "Cooking-to-ready-for-pickup":
            try:
                with connection.cursor() as cursor:
                    print("orders: ", order_id)
                    cursor.callproc('mark_order_ready_for_pickup',[order_id])
                    return JsonResponse({'status': 'success', 'message': 'Order status updated successfully!'})
            except Exception as e:
                return JsonResponse({'status': 'error', 'message': str(e)})
        elif action == "Ready-for-pickup-to-Delivered":
            try:
                with connection.cursor() as cursor:
                    print("orders: ", order_id)
                    cursor.callproc('update_order_status_and_assign_delivery',[order_id])
                return JsonResponse({'status': 'success', 'message': 'Order status updated successfully!'})
            except Exception as e:
                return JsonResponse({'status': 'error', 'message': str(e)})

        return JsonResponse({'status': 'error', 'message': 'Invalid request'})

    
#This function is used to submit a order request for a given user
def submit_user_order(request, restaurant_id, category_name):
        c_id = request.session.get('user_id')
        print(c_id, restaurant_id)
        if request.method == 'POST':
            data = json.loads(request.body)  
            order_menu = data.get('customerPaymentOrder', {}).get('orderMenu', [])
            payment_type = data.get('customerPaymentOrder', {}).get('payment_id', '')
            cursor = connection.cursor()
            cursor.callproc('CreateOrder', [c_id, payment_type, '', datetime.datetime.now(), json.dumps(order_menu), restaurant_id])
            connection.commit()
            
        return JsonResponse({'status': 'success', 'message': 'Order status updated successfully!'})


def get_vehicle_and_agent_data(agent_id):
    with connection.cursor() as cursor:
        cursor.execute("SELECT get_vehicle_and_agent_data(%s);", [agent_id])
        result = cursor.fetchone()
    return json.loads(result[0]) if result else {}


def agent_dashboard(request):
    a_id = request.session.get('user_id')
    print(a_id)
    if not a_id:
        return redirect('login')
    agent_data = get_vehicle_and_agent_data(a_id)
    return render(request, 'agent_dashboard.html', {
        'agent_data': agent_data,
    })

def update_vehicle_details(request):
    if request.method == 'POST':
        agent_id = request.POST.get('agent_id')
        v_type = request.POST.get('v_type')
        v_color = request.POST.get('v_color')
        license_number = request.POST.get('license_number')
        vehicle_number = request.POST.get('vehicle_number')
        vehicle_registration_number = request.POST.get('vehicle_registration_number')

        # Execute the stored procedure to update vehicle and agent details
        with connection.cursor() as cursor:
            cursor.callproc('UpdateVehicleDetails', [
                vehicle_number,
                v_type,
                v_color,
                vehicle_registration_number,
                agent_id,
                license_number
            ])
        
        # Redirect to the agent dashboard after successful update
        return redirect('agent_dashboard')
    return render(request, 'error_page.html')

def agent_specifice_orders(request):
    agent_id = request.session.get('user_id')
    
    if request.method == 'POST':
        data = json.loads(request.body)
        print(data)
        order_id = data.get('order_id')
        delivery_id = data.get('delivery_id')
        if not order_id or not delivery_id:
            return JsonResponse({'status': 'error', 'message': 'Order ID and Delivery ID are required'}, status=400)
        try:
            query = "CALL UpdateDeliveryStatusAndAgent(%s, %s);"
            with connection.cursor() as cursor:
                cursor.execute(query, [delivery_id, agent_id])
            return JsonResponse({'status': 'success', 'message': 'Delivery status updated successfully'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
    query = """
            SELECT GetDeliveryDetailsByAgentJSON(%s);
        """
    with connection.cursor() as cursor:
        cursor.execute(query, [agent_id])
        rows = cursor.fetchone() 
        if(rows[0] == None):
            order_data = {}
        else:
            order_data = json.loads(rows[0]) 
    return render(request, 'agent_order_dashboard.html', {
        'order_data': order_data,
    })
