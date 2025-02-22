use online_food_order_system;


DELIMITER $$
CREATE FUNCTION get_restaurant_details(user_id VARCHAR(50))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;

    SELECT JSON_OBJECT(
        'restaurant_id', r.restaurant_id,
        'category', r.category,
        'address_id', r.address_id,
        'address', JSON_OBJECT(
            'streetline_1', a.streetline_1,
            'streetline_2', a.streetline_2,
            'city', a.city,
            'state', a.state,
            'country', a.country,
            'zipcode', a.zipcode
        ),
        'user_id', u.user_id,
        'phone_number', u.phone_number,
        'email', u.email,
        'name', u.name_,
        'created_on', u.created_on,
        'updated_on', u.updated_on,
        'profile_picture', u.profile_picture
    )
    INTO result
    FROM restaurants r
    JOIN users u ON r.restaurant_id = u.user_id
    LEFT JOIN address a ON r.address_id = a.address_id
    WHERE u.user_id = user_id AND u.user_type = 'restaurant';

    RETURN result;
END$$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION GetIngredientsForRestaurantAndMenu(
    p_restaurant_id VARCHAR(50),
    p_menu_id INT
) 
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    
    -- Select all ingredients related to the given restaurant_id and menu_id
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'ingredient_name', im.ingredient_name,
            'calories', i.calories,
            'allergens', i.allergens,
            'gluten_free', i.gluten_free,
            'vegan', i.vegan
        )
    )
    INTO result
    FROM ingredient_menu im
    JOIN ingredients i ON im.ingredient_name = i.ingredient_name
    JOIN restaurant_menu rm ON rm.menu_id = im.menu_id
    WHERE rm.restaurant_id = p_restaurant_id
      AND rm.menu_id = p_menu_id;
    
    RETURN result;
END$$

DELIMITER ;


DELIMITER $$

CREATE FUNCTION GetMenuByRestaurantAndCategory(restaurant_id VARCHAR(50), food_category VARCHAR(50))
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE result JSON;
    
    -- Construct the JSON array of menu items and their ingredients
    SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'item_name', mi.item_name,
                'item_description', mi.item_description,
                'price', mi.price,
                'menu_name' , mi.menu_id
            )
    ) INTO result
    FROM restaurant_menu rm
    JOIN menu_items mi ON rm.menu_id = mi.menu_id
    JOIN cuisine_type ct ON mi.country_id = ct.country_id
    WHERE rm.restaurant_id = restaurant_id
      AND ct.category = food_category
      AND mi.availability = 1;  -- Assuming availability = 1 means the item is available

    RETURN result;
END$$

DELIMITER ;


DELIMITER $$

CREATE FUNCTION GetMenuByRestaurant(restaurant_id VARCHAR(50))
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE result JSON;
    
    -- Construct the JSON array of menu items and their details including cuisine data
    SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'item_name', mi.item_name,
                'item_description', mi.item_description,
                'price', mi.price,
                'menu_name', rm.menu_id,
                'available', mi.availability,
                'cuisine_taste', ct.taste,
                'cuisine_country', ct.country,
                'cuisine_category', ct.category
            )
    ) INTO result
    FROM restaurant_menu rm
    JOIN menu_items mi ON rm.menu_id = mi.menu_id
    JOIN cuisine_type ct ON mi.country_id = ct.country_id   -- Adjusted to use cuisine_id
    WHERE rm.restaurant_id = restaurant_id;
    
    RETURN result;
END$$

DELIMITER ;




DELIMITER $$

CREATE FUNCTION GetRestaurantsByCategory(food_category VARCHAR(50))
RETURNS JSON
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE result JSON;
    
    -- Construct the JSON array of restaurant_id and restaurant_name pairs
    SELECT JSON_ARRAYAGG(
        JSON_OBJECT(
            'restaurant_id', rm.restaurant_id,
            'restaurant_name', u.name_
        )
    ) INTO result
    FROM restaurant_menu rm
    JOIN menu_items mi ON rm.menu_id = mi.menu_id
    JOIN cuisine_type ct ON mi.country_id = ct.country_id
    JOIN restaurants r ON rm.restaurant_id = r.restaurant_id
    JOIN users u ON r.restaurant_id = u.user_id  -- Match restaurant_id with user_id from users table
    WHERE ct.category = food_category
      AND u.user_type = 'restaurant';  -- Ensure that the user is of type 'restaurant'

    RETURN result;
END$$

DELIMITER ;


-- get the food items 
DELIMITER $$

CREATE FUNCTION get_food_categories() 
RETURNS VARCHAR(255)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE categories VARCHAR(255);
    SET categories = (
        SELECT GROUP_CONCAT(DISTINCT ct.category ORDER BY ct.category)
        FROM menu_items mi
        JOIN cuisine_type ct ON mi.country_id = ct.country_id
    );
    RETURN categories;
END $$
DELIMITER ;


DELIMITER $$

CREATE FUNCTION GetCustomerDetailsByUserID(user_id VARCHAR(50))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE customer_details JSON;

    SELECT JSON_OBJECT(
            'user_id', u.user_id,
            'email', u.email,
            'phone_number', u.phone_number,
            'name', u.name_,
            'created_on', u.created_on,
            'updated_on', u.updated_on,
            'profile_picture', u.profile_picture,
            'customer_id', c.customer_id,
            'date_of_birth', c.date_of_birth,
            'gender', c.gender,
            'membership_type', c.membership_type
    )
    INTO customer_details
    FROM users u
    JOIN customers c ON u.user_id = c.customer_id
    WHERE u.user_id = user_id;

    RETURN customer_details;
END $$

DELIMITER ;

-- give all the saved address for the given customer
DELIMITER $$

CREATE FUNCTION GetAllCustomerAddressesFn(
    p_customer_id VARCHAR(50)
) RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE result JSON;

    SET result = (
        SELECT 
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'address_id', a.address_id,
                    'streetline_1', a.streetline_1,
                    'streetline_2', a.streetline_2,
                    'city', a.city,
                    'state', a.state,
                    'country', a.country,
                    'zipcode', a.zipcode
                )
            )
        FROM 
            customer_address ca
        JOIN 
            address a ON ca.address_id = a.address_id
        WHERE 
            ca.customer_id = p_customer_id
    );

    RETURN result;
END $$

DELIMITER ;

-- get all the past order given the customer id

DELIMITER $$

CREATE FUNCTION ViewPastOrdersFn(
    p_customer_id VARCHAR(50)
) RETURNS JSON
READS SQL DATA
BEGIN
    RETURN (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'order_id', cpo.order_id,
                'order_status', o.order_status,
                'order_rating', o.order_rating,
                'restaurant_id', o.restaurant_id,
                'order_date', cpo.order_date
            )
        )
        FROM 
            customer_payment_order cpo
        JOIN 
            orders o ON cpo.order_id = o.order_id
        WHERE 
            cpo.customer_id = p_customer_id
        ORDER BY 
            cpo.order_date DESC
    );
END $$

DELIMITER ;

-- get the name of restaurants nearby given the zip code
DELIMITER $$

CREATE FUNCTION GetRestaurantsByZipCodeFn(
    p_zipcode VARCHAR(10)
) RETURNS JSON
READS SQL DATA
BEGIN
    RETURN (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'restaurant_id', r.restaurant_id,
                'category', r.category,
                'streetline_1', a.streetline_1,
                'streetline_2', a.streetline_2,
                'city', a.city,
                'state', a.state,
                'country', a.country,
                'zipcode', a.zipcode
            )
        )
        FROM 
            restaurants r
        JOIN 
            address a ON r.address_id = a.address_id
        WHERE 
            a.zipcode = p_zipcode
    );
END $$

DELIMITER ;

DELIMITER $$


-- get all the restaurant name given the city name 
CREATE FUNCTION GetRestaurantsByCityFn(
    p_city_name VARCHAR(50)
) RETURNS JSON
READS SQL DATA
BEGIN
    RETURN (
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'restaurant_id', r.restaurant_id,
                'category', r.category,
                'streetline_1', a.streetline_1,
                'streetline_2', a.streetline_2,
                'city', a.city,
                'state', a.state,
                'country', a.country,
                'zipcode', a.zipcode
            )
        )
        FROM 
            restaurants r
        JOIN 
            address a ON r.address_id = a.address_id
        WHERE 
            a.city = p_city_name
    );
END $$

DELIMITER ;

-- user login 
DELIMITER $$

CREATE FUNCTION UserLoginFn(
    p_email VARCHAR(100),
    p_pass_word VARCHAR(255),
    p_user_type ENUM('customer', 'restaurant', 'agent')  -- User type parameter
) RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE user_count INT;

    -- Check if the user exists with the given credentials and user type
    SELECT COUNT(*) INTO user_count
    FROM users 
    WHERE email = p_email AND pass_word = p_pass_word AND user_type = p_user_type;

    -- If the user exists, return user details as JSON; otherwise, return an error message
    IF user_count = 1 THEN
        RETURN (
            SELECT JSON_OBJECT(
                'user_id', user_id,
                'user_type', user_type
            )
            FROM users 
            WHERE email = p_email AND pass_word = p_pass_word AND user_type = p_user_type
            LIMIT 1
        );
    ELSE
        RETURN JSON_OBJECT(
            'message', 'Invalid credentials'
        );
    END IF;
END $$

DELIMITER ;

-- get the menu items for a restaurant 

DELIMITER $$

CREATE FUNCTION GetMenuItemsByRestaurantName(
    p_restaurant_name VARCHAR(50)
)
RETURNS TABLE
RETURN
    SELECT 
        mi.item_name,
        mi.item_description,
        mi.price,
        mi.availability
    FROM 
        restaurants r
    JOIN 
        restaurant_menu rm ON r.restaurant_id = rm.restaurant_id
    JOIN 
        menu_items mi ON rm.menu_id = mi.menu_id
    WHERE 
        r.category = p_restaurant_name;

DELIMITER ;


-- get all the ingredients for a given menu id
DELIMITER $$

CREATE FUNCTION GetIngredientsByMenuId(
    p_menu_id INT
)
RETURNS TABLE
RETURN
    SELECT 
        i.ingredient_name,
        i.calories,
        i.allergens,
        i.gluten_free,
        i.vegan
    FROM 
        ingredient_menu im
    JOIN 
        ingredients i ON im.ingredient_name = i.ingredient_name
    WHERE 
        im.menu_id = p_menu_id;

DELIMITER ;


DELIMITER $$

CREATE FUNCTION GetOrdersByRestaurant(restaurantId VARCHAR(50))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;

    -- Get orders in each status: cooking, delivered, cancelled
    SELECT JSON_OBJECT(
        'cooking', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'order_id', o.order_id,
                    'menu_id', om.menu_id,
                    'menu_item_name', mi.item_name,
                    'quantity_ordered', om.quantity,
                    'bill', om.quantity * mi.price,
                    'customer_name', c.name_,
                    'order_date', cpo.order_date,
                    'payment_method', p.payment_method,
                    'payment_id', p.payment_id
                )
            )
            FROM orders o
            JOIN order_menu om ON o.order_id = om.order_id
            JOIN restaurant_menu rm ON om.menu_id = rm.menu_id AND o.restaurant_id = rm.restaurant_id
            JOIN menu_items mi ON mi.menu_id = rm.menu_id
            JOIN customer_payment_order cpo ON o.order_id = cpo.order_id
            JOIN users c ON cpo.customer_id = c.user_id
            JOIN payment p ON cpo.payment_id = p.payment_id
            WHERE o.restaurant_id = restaurantId AND o.order_status = 'cooking'
        ),
        'delivered', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'order_id', o.order_id,
                    'menu_id', om.menu_id,
                    'menu_item_name', mi.item_name,
                    'quantity_ordered', om.quantity,
                    'bill', om.quantity * mi.price,
                    'customer_name', c.name_,
                    'order_date', cpo.order_date,
                    'payment_method', p.payment_method,
                    'payment_id', p.payment_id
                )
            )
            FROM orders o
            JOIN order_menu om ON o.order_id = om.order_id
            JOIN restaurant_menu rm ON om.menu_id = rm.menu_id AND o.restaurant_id = rm.restaurant_id
            JOIN menu_items mi ON mi.menu_id = rm.menu_id
            JOIN customer_payment_order cpo ON o.order_id = cpo.order_id
            JOIN users c ON cpo.customer_id = c.user_id
            JOIN payment p ON cpo.payment_id = p.payment_id
            WHERE o.restaurant_id = restaurantId AND o.order_status = 'delivered'
        ),
        'Ready for Pickup', (
            SELECT JSON_ARRAYAGG(
                JSON_OBJECT(
                    'order_id', o.order_id,
                    'menu_id', om.menu_id,
                    'menu_item_name', mi.item_name,
                    'quantity_ordered', om.quantity,
                    'bill', om.quantity * mi.price,
                    'customer_name', c.name_,
                    'order_date', cpo.order_date,
                    'payment_method', p.payment_method,
                    'payment_id', p.payment_id
                )
            )
            FROM orders o
            JOIN order_menu om ON o.order_id = om.order_id
            JOIN restaurant_menu rm ON om.menu_id = rm.menu_id AND o.restaurant_id = rm.restaurant_id
            JOIN menu_items mi ON mi.menu_id = rm.menu_id
            JOIN customer_payment_order cpo ON o.order_id = cpo.order_id
            JOIN users c ON cpo.customer_id = c.user_id
            JOIN payment p ON cpo.payment_id = p.payment_id
            WHERE o.restaurant_id = restaurantId AND o.order_status = 'Ready for Pickup'
        )
    ) INTO result;

    RETURN result;
END$$

DELIMITER ;

DELIMITER $$

CREATE FUNCTION get_vehicle_and_agent_data(agent_id_input VARCHAR(50))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    
    SELECT JSON_OBJECT(
               'vehicle_number', v.vehicle_number,
               'v_type', v.v_type,
               'v_color', v.v_color,
               'vehicle_registration_number', v.vehicle_registration_number,
               'agent_id', v.agent_id,
               'year_of_joining', da.year_of_joining,
               'gender', da.gender,
               'age', da.age,
               'license_number', da.license_number
           )
    INTO result
    FROM vehicles v
    JOIN delivery_agents da ON v.agent_id = da.agent_id
    WHERE v.agent_id = agent_id_input
    LIMIT 1;
    
    RETURN result;
END $$

DELIMITER ;

DELIMITER $$

CREATE FUNCTION GetDeliveryDetailsByAgentJSON(
    input_agent_id VARCHAR(50)
)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;

    SELECT 
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'order_id', d.order_id,
                'restaurant_id', o.restaurant_id,
                'delivery_status', d.delivery_status,
                'delivery_id',d.delivery_id
            )
        )
    INTO result
    FROM 
        delivery d
    JOIN 
        orders o ON d.order_id = o.order_id
    WHERE 
        d.agent_id = input_agent_id and (d.delivery_status = "in progress" or d.delivery_status = "successful");

    RETURN result;
END$$

DELIMITER ;


