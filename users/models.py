# # models.py
# from django.db import models
# from enum import Enum

# # Define an enum for payment methods
# class PaymentMethod(Enum):
#     CREDIT_CARD = 'credit card'
#     PAYPAL = 'PayPal'
#     APPLEPAY = 'ApplePay'

#     def __str__(self):
#         return self.value

# # Use the Enum in your model
# class PaymentOption(models.Model):
#     payment_method = models.CharField(
#         max_length=50,
#         choices=[(method.name, method.value) for method in PaymentMethod],
#         default=PaymentMethod.CREDIT_CARD.name
#     )

#     def __str__(self):
#         return self.payment_method
# #