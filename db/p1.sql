use online_food_order_system;


-- delete user address
DELIMITER $$

CREATE PROCEDURE DeleteCustomerAddress(IN p_customer_id VARCHAR(50), IN p_address_id INT)
BEGIN
    -- Delete from the customer_address table first to maintain referential integrity
    DELETE FROM customer_address
    WHERE customer_id = p_customer_id
    AND address_id = p_address_id;

    -- Then, delete the address from the address table
    DELETE FROM address
    WHERE address_id = p_address_id;
END$$

DELIMITER ;

-- update the address
DELIMITER $$

CREATE PROCEDURE UpdateCustomerAddress(
    IN p_customer_id VARCHAR(50), 
    IN p_address_id INT,
    IN p_streetline_1 VARCHAR(100),
    IN p_streetline_2 VARCHAR(50),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_country VARCHAR(50),
    IN p_zipcode VARCHAR(9)
)
BEGIN
    UPDATE address
    SET 
        streetline_1 = p_streetline_1,
        streetline_2 = p_streetline_2,
        city = p_city,
        state = p_state,
        country = p_country,
        zipcode = p_zipcode
    WHERE address_id = p_address_id;
END$$

DELIMITER ;

-- insert the new user address 
DELIMITER $$

CREATE PROCEDURE InsertCustomerAddress(
    IN p_customer_id VARCHAR(50),
    IN p_streetline_1 VARCHAR(100),
    IN p_streetline_2 VARCHAR(50),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_country VARCHAR(50),
    IN p_zipcode VARCHAR(9)
)
BEGIN
    -- Insert the new address into the address table
    INSERT INTO address (
        streetline_1, streetline_2, city, state, country, zipcode
    )
    VALUES (
        p_streetline_1, p_streetline_2, p_city, p_state, p_country, p_zipcode
    );

    -- Get the last inserted address_id
    SET @last_address_id = LAST_INSERT_ID();

    -- Insert the relationship into the customer_address table
    INSERT INTO customer_address (
        customer_id, address_id
    )
    VALUES (
        p_customer_id, @last_address_id
    );
END$$

DELIMITER ;
 -- restaurant address update
 -- insert the new user address 
DELIMITER $$


DELIMITER $$

CREATE PROCEDURE UpdateUserPhoneNumber(
    IN new_user_id VARCHAR(255), 
    IN new_phone_number VARCHAR(15)
)
BEGIN
    DECLARE user_exists INT;

    -- Check if the user exists
    SELECT COUNT(*) INTO user_exists
    FROM users
    WHERE user_id = new_user_id;

    IF user_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User ID does not exist';
    ELSE
        -- Update the phone number
        UPDATE users
        SET phone_number = new_phone_number, 
            updated_on = NOW()
        WHERE user_id = new_user_id;
    END IF;
END$$

DELIMITER ;



-- user sign up
DELIMITER $$

CREATE PROCEDURE UserSignup(
    IN p_user_id VARCHAR(50),
    IN p_pass_word VARCHAR(255),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(10),
    IN p_name_ VARCHAR(100),
    IN p_user_type ENUM('customer', 'restaurant', 'agent')
)
BEGIN
    DECLARE email_exists INT;

    -- Check if email already exists
    SELECT COUNT(*) INTO email_exists 
    FROM users 
    WHERE email = p_email;

    IF email_exists = 0 THEN
        -- Insert new user
        INSERT INTO users (user_id, pass_word, email, phone_number, name_, user_type)
        VALUES (p_user_id, p_pass_word, p_email, p_phone_number, p_name_, p_user_type);

        SELECT 'User registered successfully' AS message;
    ELSE
        SELECT 'Email already exists' AS message;
    END IF;
END $$

DELIMITER ;
-- CreateCustomerOrder
DELIMITER $$

CREATE PROCEDURE CreateCustomerOrder(
    IN p_customer_id VARCHAR(50),
    IN p_restaurant_id VARCHAR(50),
    IN p_menu_items JSON
)
BEGIN
    DECLARE new_order_id VARCHAR(50);
    DECLARE item_id INT;
    DECLARE item_quantity INT;

    -- Generate unique order ID
    SET new_order_id = UUID();

    -- Insert into orders table
    INSERT INTO orders (order_id, order_status, restaurant_id)
    VALUES (new_order_id, 'cooking', p_restaurant_id);

    -- Iterate through menu items JSON
    WHILE JSON_LENGTH(p_menu_items) > 0 DO
        SET item_id = JSON_UNQUOTE(JSON_EXTRACT(p_menu_items, '$[0].menu_id'));
        SET item_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_menu_items, '$[0].quantity'));

        INSERT INTO order_menu (order_id, menu_id, quantity)
        VALUES (new_order_id, item_id, item_quantity);

        SET p_menu_items = JSON_REMOVE(p_menu_items, '$[0]');
    END WHILE;

    SELECT 'Order created successfully', new_order_id AS order_id;
END $$

DELIMITER ;




-- AssignDeliveryAgent
DELIMITER $$

CREATE PROCEDURE AssignDeliveryAgent(
    IN p_order_id VARCHAR(50),
    IN p_agent_id VARCHAR(50),
    IN p_estimated_time TIME
)
BEGIN
    INSERT INTO delivery (delivery_id, delivery_status, estimated_arrival_time, agent_id, order_id)
    VALUES (UUID(), 'in progress', p_estimated_time, p_agent_id, p_order_id);

    SELECT 'Delivery agent assigned successfully' AS message;
END $$

DELIMITER ;

-- UpdateOrderStatus
DELIMITER $$

CREATE PROCEDURE UpdateOrderStatus(
    IN p_order_id VARCHAR(50),
    IN p_new_status ENUM('delivered', 'cancelled', 'cooking')
)
BEGIN
    UPDATE orders
    SET order_status = p_new_status
    WHERE order_id = p_order_id;

    SELECT 'Order status updated successfully' AS message;
END $$

DELIMITER ;

-- AddPayment
DELIMITER $$

CREATE PROCEDURE AddPayment(
    IN p_payment_id VARCHAR(100),
    IN p_payment_method ENUM('credit card', 'PayPal', 'ApplePay'),
    IN p_customer_id VARCHAR(50),
    IN p_order_id VARCHAR(50),
    IN p_order_date TIMESTAMP
)
BEGIN
    INSERT INTO payment (payment_id, payment_method)
    VALUES (p_payment_id, p_payment_method);

    INSERT INTO customer_payment_order (customer_id, payment_id, order_id, order_date)
    VALUES (p_customer_id, p_payment_id, p_order_id, p_order_date);

    SELECT 'Payment added successfully' AS message;
END $$

DELIMITER ;

-- AddMenuItem
DELIMITER $$

CREATE PROCEDURE AddMenuItem(
    IN p_restaurant_id VARCHAR(50),
    IN p_item_name VARCHAR(50),
    IN p_item_description TEXT,
    IN p_price DECIMAL(10, 2),
    IN p_availability BOOLEAN,
    IN p_taste VARCHAR(50),
    IN p_country VARCHAR(50),
    IN p_category VARCHAR(50)
)
BEGIN
    DECLARE new_menu_id INT;
    DECLARE new_country_id INT;
    DECLARE existing_menu_id INT;
    DECLARE done INT DEFAULT 0;

    -- Declare the cursor to loop through cuisine_type table
    DECLARE cuisine_cursor CURSOR FOR
        SELECT country_id
        FROM cuisine_type
        WHERE category = p_category AND country = p_country AND taste = p_taste;

    -- Declare a continue handler to set 'done' to 1 when no rows are left
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor to start iterating
    OPEN cuisine_cursor;

    -- Loop through the rows returned by the cursor
    read_loop: LOOP
        FETCH cuisine_cursor INTO new_country_id;

        -- If we find a match, exit the loop
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- Check if the country_id matches the provided one
        IF new_country_id IS NOT NULL THEN
            -- If a matching country_id is found, exit the loop
            LEAVE read_loop;
        END IF;
    END LOOP;

    -- Close the cursor after finishing the loop
    CLOSE cuisine_cursor;

    -- If no match is found, insert the new entry into cuisine_type
    IF new_country_id IS NULL THEN
        -- Insert into cuisine_type if the country_id is not found
        INSERT INTO cuisine_type (taste, country, category)
        VALUES (p_taste, p_country, p_category);
        
        -- Get the newly inserted country_id
        SET new_country_id = LAST_INSERT_ID();
    END IF;

    -- Check if the menu item already exists in the menu_items table
    SELECT menu_id INTO existing_menu_id
    FROM menu_items
    WHERE item_name = p_item_name
      AND item_description = p_item_description
      AND price = p_price
      AND availability = p_availability
      AND country_id = new_country_id
    LIMIT 1;

    -- If the item already exists, use the existing menu_id
    IF existing_menu_id IS NOT NULL THEN
        SET new_menu_id = existing_menu_id;
    ELSE
        -- Insert into menu_items table as a new entry
        INSERT INTO menu_items (item_name, item_description, price, availability, country_id)
        VALUES (p_item_name, p_item_description, p_price, p_availability, new_country_id);

        SET new_menu_id = LAST_INSERT_ID();  -- Get the newly inserted menu_id
    END IF;

    -- Link the item to the restaurant's menu
    INSERT INTO restaurant_menu (restaurant_id, menu_id)		
    VALUES (p_restaurant_id, new_menu_id);

    SELECT 'Menu item added successfully' AS message, new_menu_id AS menu_id;
END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE UpdateMenuItem(
    IN p_restaurant_id VARCHAR(50),
    IN p_item_name VARCHAR(50),
    IN p_item_description TEXT,
    IN p_price DECIMAL(10, 2),
    IN p_availability BOOLEAN
)
BEGIN
    DECLARE existing_menu_id INT;
    DECLARE duplicate_entry INT;

    -- Step 1: Check if the menu item already exists in the menu_items table
    SELECT menu_id INTO existing_menu_id
    FROM menu_items
    WHERE item_name = p_item_name
    AND item_description = p_item_description
    LIMIT 1;

    -- Step 2: If the menu item already exists, update the restaurant_menu table
    IF existing_menu_id IS NOT NULL THEN
        -- Check if the combination of restaurant_id and existing_menu_id is already present in restaurant_menu
        SELECT COUNT(*) INTO duplicate_entry
        FROM restaurant_menu
        WHERE restaurant_id = p_restaurant_id
        AND menu_id = existing_menu_id;

        IF duplicate_entry = 0 THEN
            -- Update the restaurant_menu with the existing menu_id if it doesn't exist already
            UPDATE restaurant_menu
            SET menu_id = existing_menu_id
            WHERE restaurant_id = p_restaurant_id;
            SELECT 'Menu item updated successfully with existing menu_id.' AS message;
        ELSE
            -- If the combination already exists, return a message indicating no update is needed
            SELECT 'No changes made: Combination of restaurant_id and menu_id already exists.' AS message;
        END IF;

        -- Step 3: Update the price, description, and availability of the existing menu item in menu_items
        UPDATE menu_items
        SET item_description = p_item_description,
            price = p_price,
            availability = p_availability
        WHERE menu_id = existing_menu_id;

        SELECT 'Menu item details updated successfully.' AS message;

    ELSE
        -- If the menu item does not exist, return a message indicating that the item was not found
        SELECT 'No menu item found with the provided name and description.' AS message;
    END IF;

END $$

DELIMITER ;
 -- delete a menu item 
DELIMITER $$

CREATE PROCEDURE DeleteMenuItem(
    IN input_restaurant_id VARCHAR(50),
    IN input_menu_id INT,
    OUT deletion_successful BOOLEAN
)
BEGIN
    DELETE FROM restaurant_menu
    WHERE restaurant_id = input_restaurant_id
      AND menu_id = input_menu_id;

    -- Check if the deletion was successful
    SET deletion_successful = ROW_COUNT() > -1;
END$$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE UpdateOrderStatusAndCreateDelivery(IN p_order_id VARCHAR(50))
BEGIN
    -- Variable to store the randomly selected delivery agent's ID
    DECLARE agent_id VARCHAR(50);
    
    -- Change the order status to 'delivered'
    UPDATE orders
    SET order_status = 'delivered'
    WHERE order_id = p_order_id;
    
    -- Debugging: Check if the `order_id` exists and is updated correctly
    SELECT p_order_id AS 'Order ID', 'Order status updated to delivered.' AS status;

    -- Select a random delivery agent from the `delivery_agents` table
    SELECT agent_id INTO agent_id
    FROM delivery_agents
    ORDER BY RAND()
    LIMIT 1;

    -- Debugging: Show the selected agent_id
    SELECT agent_id AS 'Selected Agent ID';
    
    -- If no agent is found, raise an error
    IF agent_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No delivery agents available.';
    ELSE
        -- Insert a new entry into the `delivery` table with the selected agent
        INSERT INTO delivery (
            delivery_id, 
            delivery_status, 
            instructions, 
            estimated_arrival_time, 
            delivery_rating, 
            agent_id, 
            actual_delivery_time, 
            order_id
        )
        VALUES (
            UUID(),  -- Generate a unique delivery ID
            'in progress', 
            'N/A',  -- Placeholder for instructions (you can modify as needed)
            '00:00:00',  -- Placeholder for estimated arrival time
            NULL,  -- Placeholder for delivery rating (if not yet rated)
            agent_id, 
            '00:00:00',  -- Placeholder for actual delivery time
            p_order_id
        );
    END IF;
    
END $$


DELIMITER ;

CREATE PROCEDURE update_order_status_and_assign_delivery(IN given_order_id VARCHAR(50))
BEGIN
    -- Declare variables
    DECLARE first_agent_id VARCHAR(50);
    DECLARE current_delivery_time TIME;

    -- Get the first available delivery agent (first in the queue)
    SELECT agent_id, year_of_joining, gender, age, license_number
    INTO first_agent_id, @year_of_joining, @gender, @age, @license_number
    FROM delivery_agents
    ORDER BY year_of_joining, agent_id  -- Ensure FIFO order
    LIMIT 1;

    -- Store agent details in the temporary table
    INSERT INTO temp_delivery_agent (agent_id, year_of_joining, gender, age, license_number)
    VALUES (first_agent_id, @year_of_joining, @gender, @age, @license_number);

    -- Get current time for estimated arrival time
    SET current_delivery_time = CURRENT_TIME;

    -- Update order status to 'delivered'
    UPDATE orders 
    SET order_status = 'delivered' 
    WHERE order_id = given_order_id;

    -- Insert entry into the delivery table with 'in progress' status
    INSERT INTO delivery (delivery_id, delivery_status, instructions, estimated_arrival_time, delivery_rating, agent_id, actual_delivery_time, order_id)
    VALUES (UUID(), 'in progress', NULL, current_delivery_time, NULL, first_agent_id, '0.00', given_order_id);

    -- Remove the agent from the delivery_agents table (take the agent for delivery)
    DELETE FROM delivery_agents 
    WHERE agent_id = first_agent_id;

END $$

DELIMITER ;


DELIMITER ;
CREATE TABLE IF NOT EXISTS temp_delivery_agent (
    agent_id VARCHAR(50) PRIMARY KEY,
    year_of_joining YEAR,
    gender ENUM('Male','Female','Others'),
    age INT,
    license_number VARCHAR(50)
);

DELIMITER $$


DELIMITER $$

CREATE PROCEDURE complete_delivery_and_return_agent(IN delivery_id VARCHAR(50), IN actual_delivery_time TIME)
BEGIN
    DECLARE assigned_agent_id VARCHAR(50);

    -- Get the agent_id for the delivery. Ensure only one row is returned by limiting the query to one row.
    SELECT agent_id 
    INTO assigned_agent_id
    FROM delivery
    WHERE delivery_id = delivery_id
    LIMIT 1;  -- Ensure only one row is returned

    -- Update the delivery status to 'successful' and add actual delivery time
    UPDATE delivery
    SET delivery_status = 'successful',
        actual_delivery_time = actual_delivery_time
    WHERE delivery_id = delivery_id;

    -- Re-insert the agent back into the delivery_agents table from the temp table
    INSERT INTO delivery_agents (agent_id, year_of_joining, gender, age, license_number)
    SELECT agent_id, year_of_joining, gender, age, license_number
    FROM temp_delivery_agent
    WHERE agent_id = assigned_agent_id;

    -- Optionally, delete the entry from the temporary table after reinsertion
    DELETE FROM temp_delivery_agent
    WHERE agent_id = assigned_agent_id;

END $$

DELIMITER ;


DELIMITER $$

CREATE PROCEDURE mark_order_ready_for_pickup(IN given_order_id VARCHAR(50))
BEGIN
    -- Update the order status to 'ready for pickup' where the current status is 'cooking'
    UPDATE orders 
    SET order_status = 'ready for pickup'
    WHERE order_id = given_order_id
      AND order_status = 'cooking';

    -- Optionally, check if no rows were affected (if the order was not in 'cooking' state)
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Order is not in the cooking state or does not exist.';
    END IF;
END $$

DELIMITER ;

DELIMITER //

CREATE PROCEDURE CreateOrder(
    IN p_customer_id VARCHAR(50),
    IN p_payment_type VARCHAR(50),
    IN p_payment_description VARCHAR(255), -- Optional
    IN p_order_date TIMESTAMP,
    IN p_menu_details JSON,
    IN p_restaurant_id VARCHAR(50)
)
BEGIN
    DECLARE v_payment_id VARCHAR(50);
    DECLARE v_order_id VARCHAR(50);
    DECLARE v_menu_id VARCHAR(50);
    DECLARE v_quantity INT;
    DECLARE v_index INT DEFAULT 0;


    -- Generate a unique order_id for the order
    REPEAT
        SET v_order_id = UUID();
    UNTIL NOT EXISTS (SELECT 1 FROM orders WHERE order_id = v_order_id)
    END REPEAT;

    -- Insert into orders table with default order status 'cooking'
    INSERT INTO orders (order_id, order_status, restaurant_id)
    VALUES (v_order_id, 'cooking', p_restaurant_id);

    -- Generate a unique payment_id
    REPEAT
        SET v_payment_id = UUID();
    UNTIL NOT EXISTS (SELECT 1 FROM payment WHERE payment_id = v_payment_id)
    END REPEAT;

    -- Insert into payment table
    INSERT INTO payment (payment_id, payment_method, payment_description)
    VALUES (v_payment_id, p_payment_type, p_payment_description);

    -- Insert into customer_payment_order table
    INSERT INTO customer_payment_order (customer_id, payment_id, order_id, order_date)
    VALUES (p_customer_id, v_payment_id, v_order_id, p_order_date);

    -- Loop through menu_details (JSON format: [{"menu_id": "menu1", "quantity": 2}, ...])
    WHILE v_index < JSON_LENGTH(p_menu_details) DO
        SET v_menu_id = JSON_UNQUOTE(JSON_EXTRACT(p_menu_details, CONCAT('$[', v_index, '].menu_id')));
        SET v_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_menu_details, CONCAT('$[', v_index, '].quantity')));

        -- Insert each menu_id, quantity, and restaurant_id into order_details
        INSERT INTO order_menu (order_id, menu_id, quantity)
        VALUES (v_order_id, v_menu_id, v_quantity);

        -- Move to next index
        SET v_index = v_index + 1;
    END WHILE;
    
    
    
END;
//

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE RegisterCustomerWithAddress(
    IN p_user_id VARCHAR(50),
    IN p_pass_word VARCHAR(255),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(10),
    IN p_name_ VARCHAR(100),
    IN p_date_of_birth DATE,
    IN p_gender ENUM('Male', 'Female', 'Others'),
    IN p_membership_type ENUM('General', 'Premium'),
    IN p_streetline_1 VARCHAR(100),
    IN p_streetline_2 VARCHAR(50),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_country VARCHAR(50),
    IN p_zipcode VARCHAR(9)
)
BEGIN
    DECLARE email_exists INT;
    DECLARE existing_address_id INT;
    DECLARE address_exists INT;
    DECLARE membership ENUM('General', 'Premium');
    
    -- Step 1: Check if the email already exists in the `users` table
    SELECT COUNT(*) INTO email_exists 
    FROM users 
    WHERE email = p_email;

    IF email_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email already exists. Cannot register user.';
    ELSE
        -- Step 2: Set membership type to General if not provided
        SET membership = IFNULL(p_membership_type, 'General');

        -- Step 3: Insert into `users` table
        INSERT INTO users (user_id, pass_word, email, phone_number, name_, user_type, created_on, updated_on)
        VALUES (p_user_id, p_pass_word, p_email, p_phone_number, p_name_, 'customer', NOW(), NOW());

        -- Step 4: Insert into `customers` table
        INSERT INTO customers (customer_id, date_of_birth, gender, membership_type)
        VALUES (p_user_id, p_date_of_birth, p_gender, membership);

        -- Step 5: Check if the address already exists in the `address` table
        SELECT address_id INTO existing_address_id 
        FROM address
        WHERE streetline_1 = p_streetline_1
          AND streetline_2 = p_streetline_2
          AND city = p_city
          AND state = p_state
          AND country = p_country
          AND zipcode = p_zipcode;

        SET address_exists = ROW_COUNT();

        IF address_exists > 0 THEN
            -- Step 6: Map the existing address_id in the `customer_address` table
            INSERT INTO customer_address (customer_id, address_id)
            VALUES (p_user_id, existing_address_id);
        ELSE
            -- Step 7: Insert the new address into the `address` table
            INSERT INTO address (streetline_1, streetline_2, city, state, country, zipcode)
            VALUES (p_streetline_1, p_streetline_2, p_city, p_state, p_country, p_zipcode);

            -- Step 8: Get the newly generated address_id
            SET existing_address_id = LAST_INSERT_ID();

            -- Step 9: Map the new address_id in the `customer_address` table
            INSERT INTO customer_address (customer_id, address_id)
            VALUES (p_user_id, existing_address_id);
        END IF;

        -- Step 10: Return success message
        SELECT 'Customer registered successfully with address.' AS message;
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE RegisterRestaurant (
    IN p_user_id VARCHAR(50),
    IN p_pass_word VARCHAR(255),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(10),
    IN p_name_ VARCHAR(100),
    IN p_created_on DATETIME,
    IN p_updated_on DATETIME,
    IN p_user_type ENUM('customer', 'restaurant', 'agent'),
    IN p_streetline_1 VARCHAR(100),
    IN p_streetline_2 VARCHAR(50),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    IN p_country VARCHAR(50),
    IN p_zipcode VARCHAR(9),
    IN p_category VARCHAR(50)
)
BEGIN
    DECLARE v_address_id INT;

    -- Check if the user already exists
    IF EXISTS (
        SELECT 1
        FROM users
        WHERE user_id = p_user_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User ID already exists.';
    END IF;

    -- Insert user details into the users table
    INSERT INTO users (
        user_id, pass_word, email, phone_number, name_, created_on, 
        updated_on, profile_picture, user_type
    ) VALUES (
        p_user_id, p_pass_word, p_email, p_phone_number, p_name_,
        p_created_on, p_updated_on, NULL, p_user_type
    );

    -- If the user type is 'restaurant', handle address mapping
    IF p_user_type = 'restaurant' THEN
        -- Check if the address already exists
        SELECT address_id
        INTO v_address_id
        FROM address
        WHERE streetline_1 = p_streetline_1
          AND streetline_2 = p_streetline_2
          AND city = p_city
          AND state = p_state
          AND country = p_country
          AND zipcode = p_zipcode
        LIMIT 1;

        -- If the address does not exist, insert a new address
        IF v_address_id IS NULL THEN
            INSERT INTO address (
                streetline_1, streetline_2, city, state, country, zipcode
            ) VALUES (
                p_streetline_1, p_streetline_2, p_city, p_state, p_country, p_zipcode
            );
            SET v_address_id = LAST_INSERT_ID();
        END IF;

        -- Insert the restaurant details into the restaurant table
        INSERT INTO restaurants (
            restaurant_id, category, address_id
        ) VALUES (
            p_user_id, p_category, v_address_id
        );
    END IF;
END$$

DELIMITER ;



DELIMITER $$

CREATE PROCEDURE RegisterAgent(
    IN p_user_id VARCHAR(50),
    IN p_pass_word VARCHAR(255),
    IN p_email VARCHAR(100),
    IN p_phone_number VARCHAR(10),
    IN p_name_ VARCHAR(100),
    IN p_user_type ENUM('customer', 'restaurant', 'agent'),
    IN p_vehicle_number VARCHAR(50),
    IN p_v_type VARCHAR(50),
    IN p_v_color VARCHAR(50),
    IN p_vehicle_registration_number VARCHAR(50),
    IN p_agent_id VARCHAR(50),
    IN p_year_of_joining YEAR,
    IN p_gender ENUM('Male', 'Female', 'Others'),
    IN p_age INT,
    IN p_license_number VARCHAR(50),
    OUT p_status_message VARCHAR(255) -- OUT parameter for the status message
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback transaction in case of an error
        ROLLBACK;

        -- Include diagnostic information in the status message
        SET p_status_message = CONCAT('Error: Registration failed at step "', @current_step, '". Transaction rolled back.');
    END;

    -- Variable to track the current step
    SET @current_step = 'Starting transaction';

    -- Start a transaction
    START TRANSACTION;

    -- Insert into users table
    SET @current_step = 'Inserting into users table';
    INSERT INTO users (user_id, pass_word, email, phone_number, name_, created_on, updated_on, profile_picture, user_type)
    VALUES (p_user_id, p_pass_word, p_email, p_phone_number, p_name_, NOW(), NOW(), null, p_user_type);

    -- Insert into vehicles table if the user is of type 'agent'
    IF p_user_type = 'agent' THEN
    
		-- Insert into delivery_agents table
        SET @current_step = 'Inserting into delivery_agents table';
        INSERT INTO delivery_agents (agent_id, year_of_joining, gender, age, license_number, dstatus)
        VALUES (p_user_id, p_year_of_joining, p_gender, p_age, p_license_number, 'free');
        
        SET @current_step = 'Inserting into vehicles table';
        INSERT INTO vehicles (vehicle_number, v_type, v_color, vehicle_registration_number, agent_id)
        VALUES (p_vehicle_number, p_v_type, p_v_color, p_vehicle_registration_number, p_user_id);

    END IF;

    -- Commit the transaction
    SET @current_step = 'Committing transaction';
    COMMIT;

    -- Set success message
    SET p_status_message = 'Success: Registration completed successfully.';
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE UpdateDeliveryStatusAndAgent(
    IN input_delivery_id VARCHAR(50),
    IN input_agent_id VARCHAR(50)
)
BEGIN
    -- Check if the delivery entry exists and is assigned to the agent
    IF EXISTS (
        SELECT 1
        FROM delivery
        WHERE delivery_id = input_delivery_id
          AND agent_id = input_agent_id
    ) THEN
        -- Update the delivery status to 'successful'
        UPDATE delivery
        SET delivery_status = 'successful'
        WHERE delivery_id = input_delivery_id;

        -- Update the agent's status to 'free'
        UPDATE delivery_agents
        SET dstatus = 'free'
        WHERE agent_id = input_agent_id;
    ELSE
        -- If no matching delivery entry exists, raise an error
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No matching delivery found for the provided delivery_id and agent_id';
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE update_order_status_and_assign_delivery(IN given_order_id VARCHAR(50))
BEGIN
    -- Declare variables
    DECLARE first_agent_id VARCHAR(50);
    DECLARE current_delivery_time TIME;

    -- Get the first available (free) delivery agent (first in the queue)
    SELECT agent_id, year_of_joining, gender, age, license_number
    INTO first_agent_id, @year_of_joining, @gender, @age, @license_number
    FROM delivery_agents
    WHERE dstatus = 'free'  -- Only consider free agents
    ORDER BY year_of_joining, agent_id  -- Ensure FIFO order
    LIMIT 1;

    -- If no free agent is found, raise an error or handle accordingly
    IF first_agent_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No free agents available';
    END IF;


    -- Get current time for estimated arrival time
    SET current_delivery_time = CURRENT_TIME;

    -- Update order status to 'delivered'
    UPDATE orders 
    SET order_status = 'delivered' 
    WHERE order_id = given_order_id;

    -- Insert entry into the delivery table with 'in progress' status
    INSERT INTO delivery (delivery_id, delivery_status, instructions, estimated_arrival_time, delivery_rating, agent_id, actual_delivery_time, order_id)
    VALUES (UUID(), 'in progress', NULL, current_delivery_time, NULL, first_agent_id, '0.00', given_order_id);

    -- Update the agent's status to 'busy'
    UPDATE delivery_agents
    SET dstatus = 'busy'
    WHERE agent_id = first_agent_id;

END $$

DELIMITER ;






