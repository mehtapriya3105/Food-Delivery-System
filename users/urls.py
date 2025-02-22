# users/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('signup/', views.user_signup_view, name='signup'),
    path('signup/customer/extended/', views.user_signup_view_extended, name='signup_extended'),
    path('signup/customer/address/', views.get_new_user_address, name='get_new_user_address'),
    path('signup/restaurant/extended/',views.restaurant_signup_view_extended,name='restro_extended'),
    path('signup/restaurant/address/',views.get_new_restaurant_address,name="restro_address"),
    path('signup/agent/extended/',views.get_agent_login_extended,name = "agent_extended"),
    path('sign/agent/vehicle-details/',views.get_new_agent_vehicle_details,name = "vehicle_details"),
    path('dashboard/', views.customer_dashboard, name='customer_dashboard'),
    path('view-details/', views.get_customer_details, name='get_customer_details'),
    path('edit-phone-number/', views.edit_phone_number, name='edit_phone_number'),
    path('address-book/', views.address_book, name='address_book'),
    path('<str:category>/', views.restaurant_list_by_category, name='restaurant_list_by_category'),
    path('restaurant/menu/<str:restaurant_id>/<str:category_name>/submit-order/',views.submit_user_order,name = "submit_user_order"),
    path('restaurant/menu/<str:restaurant_id>/', views.restaurant_menu, name='restaurant_menu'),
    path('restaurant/menu/<str:restaurant_id>/<str:category_name>/', views.restaurant_menu, name='restaurant_menu'),
    path('restaurant/menu/<str:restaurant_id>/ingredients/<int:menu_id>/', views.get_ingredients_for_item, name='get_ingredients_for_item'),
    path('restaurant/dashboard/', views.restaurant_dashboard_view, name='restaurant_dashboard'),
    path('restaurant/menu/', views.restaurant_menu_for_restuarant_login, name='menu'),
    path('restaurant/order/', views.get_orders_by_status, name='orders'),
    path('restaurant/order/update-from-cooking/', views.update_order_status, name='update_order_status'),
    path('agent/dashboard/', views.agent_dashboard, name='agent_dashboard'),
    path('agent/dashboard/update-vehicle-details', views.update_vehicle_details, name='update_vehicle_data'),
    path('agent/dashboard/orders', views.agent_specifice_orders, name='agent_specifice_orders'),
    path('address-book/delete_Add/',views.delete_address,name='delete_Add'),
]
