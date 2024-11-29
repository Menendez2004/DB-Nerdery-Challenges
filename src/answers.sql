-- Your answers here:
-- 1
SELECT
    type,
    SUM(mount) AS total_money
FROM
    accounts
GROUP BY
    type
ORDER BY
    type ASC;



-- 2
-- SELECT 
--     user_id,
--     COUNT(*) AS current_account_count
-- FROM 
--     accounts
-- WHERE 
--     type = 'CURRENT_ACCOUNT'
-- GROUP BY 
--     user_id
-- HAVING 
--     COUNT(*) >=2; posible solution cuzz returns the user_id and the number of current accounts



SELECT
    COUNT(*) AS total_users
FROM
    (
        SELECT
            user_id
        FROM
            accounts
        WHERE
            type = 'CURRENT_ACCOUNT'
        GROUP BY
            user_id
        HAVING
            COUNT(*) >= 2
    );

-- 3
SELECT
    TYPE,
    account_id,
    mount
FROM
    accounts
ORDER BY
    mount DESC
LIMIT
    5;

-- 4
SELECT
    user_id,
    account_id,
    SUM(mount) AS total_money
FROM
    accounts
GROUP BY
    account_id,
    user_id
ORDER BY
    total_money DESC
LIMIT
    3;





-- 5

--(A) First, get the ammount for the account 3b79e403-c788-495a-a8ca-86ad7643afaf and fd244313-36e5-4a17-a27c-f8265bc46590 after all their movements. 
SELECT 
    a.id AS account_id,
    a.mount+
	(SUM(
        CASE 
            WHEN m.account_from = a.id THEN -m.mount 
            WHEN m.account_to = a.id THEN m.mount  
        END
    )) AS final_account_amount,
    ARRAY_AGG(ROW(
        m.type, 
        m.account_from, 
        m.account_to, 
        m.mount
    )) AS movements
FROM 
    accounts a
INNER JOIN 
    movements m
ON 
    a.id IN (m.account_from, m.account_to)
WHERE 
    a.id IN ('3b79e403-c788-495a-a8ca-86ad7643afaf', 'fd244313-36e5-4a17-a27c-f8265bc46590')
GROUP BY 
    a.id, a.mount;




--(B) Add a new movement with the information: from: 3b79e403-c788-495a-a8ca-86ad7643afaf make a transfer to fd244313-36e5-4a17-a27c-f8265bc46590 mount: 50.75
DO $$ 
DECLARE
    first_account UUID := '3b79e403-c788-495a-a8ca-86ad7643afaf';
    second_account UUID := 'fd244313-36e5-4a17-a27c-f8265bc46590';
    transfer_amount NUMERIC := 80;
BEGIN

    UPDATE accounts
    SET mount = mount - transfer_amount
    WHERE id = first_account;

    UPDATE accounts
    SET mount = mount + transfer_amount
    WHERE id = second_account;

    INSERT INTO movements (id, type, account_from, account_to, mount, created_at, updated_at)
    VALUES (
        gen_random_uuid(),  
        'TRANSFER',         
        first_account,      
        second_account,     
        transfer_amount,    
        NOW(),              
        NOW()               
    );

    RAISE NOTICE 'Transferencia completada de % a % con un monto de %', 
                 first_account, second_account, transfer_amount;
END $$;




-----------------------------------------
--Shows the result of the tranfer--
-----------------------------------------
SELECT 
    m.type, 
    m.account_from, 
    m.account_to, 
    m.mount AS transferred_amount
FROM movements m
WHERE m.account_from = '3b79e403-c788-495a-a8ca-86ad7643afaf'
   OR m.account_to = '3b79e403-c788-495a-a8ca-86ad7643afaf'
ORDER BY m.created_at ASC;



--(c) Add a new movement with the information: from: 3b79e403-c788-495a-a8ca-86ad7643afaf type: OUT mount: 731823.56
DO $$ 
DECLARE
    current_balance NUMERIC;
	first_account UUID:= '3b79e403-c788-495a-a8ca-86ad7643afaf';
	out_amount NUMERIC := 731823.56;
BEGIN

    SELECT a.mount INTO current_balance
    FROM accounts a
    WHERE a.id = first_account;

    IF current_balance < out_amount THEN
        RAISE EXCEPTION 'Saldo insuficiente para realizar el movimiento, transacción rechazada';
    END IF;

    INSERT INTO movements (id, type, account_from, account_to, mount, created_at, updated_at)
    VALUES (
        gen_random_uuid(),
        'OUT', 
        first_account,
		NULL,
		out_amount,
        now(),
        now()
    );
	
EXCEPTION
WHEN OTHERS THEN
    RAISE NOTICE '*** Error procesando la transacción con monto %. Saldo disponible: % % ** Haciendo ROLLBACK **', 
                 out_amount, current_balance, CHR(10);
    ROLLBACK;
    RETURN;

END $$;

--(d). Put your answer here if the transaction fails(YES/NO): Yes  the  is failed cuz the mount is higher than the current balance 

--(e and f). If the transaction fails, make the correction on step c to avoid the failure (the way to avoid the failure is tranfer less money than the current balance)


--(g) How much money the account fd244313-36e5-4a17-a27c-f8265bc46590 have:

SELECT 
    a.id AS account_id,
    a.mount + 
	SUM(
        CASE 
            WHEN m.account_from = a.id THEN -m.mount 
            WHEN m.account_to = a.id THEN m.mount  
        END
    )AS total_money
FROM 
    accounts a
INNER JOIN 
    movements m
ON 
    a.id IN (m.account_from, m.account_to)
WHERE 
    a.id IN ('fd244313-36e5-4a17-a27c-f8265bc46590')
GROUP BY 
    a.id, a.mount;


-- 6

SELECT 
    u.id AS user_id,
    u.name AS user_name,
    u.email AS user_email,
    a.id AS account_id,
    m.id AS movement_id,
    m.type AS movement_type,
    m.account_from AS account_from,
    m.account_to AS account_to
FROM 
    users u
INNER JOIN 
    accounts a
ON 
    u.id = a.user_id
INNER JOIN 
    movements m
ON 
    a.id IN (m.account_from, m.account_to)
WHERE 
    a.id = '3b79e403-c788-495a-a8ca-86ad7643afaf'
ORDER BY 
    m.created_at ASC;

-- 7

SELECT 
    u.name AS user,
    u.email AS email,
    SUM(a.mount) AS total_money
FROM 
    users u
INNER JOIN 
    accounts a
ON 
    u.id = a.user_id
GROUP BY 
    u.id, u.name, u.email
ORDER BY 
    total_money DESC
LIMIT 1;

--8
SELECT 
    u.name AS user_name,
    a.id AS account_id,
    a.type AS account_type,
    m.id AS UUID_movement,
    m.type AS movement_type,
    m.account_from AS account_from,
    m.account_to AS account_to,
    m.created_at AS movement_date
FROM 
    users u
INNER JOIN 
    accounts a
ON 
    u.id = a.user_id
LEFT JOIN 
    movements m
ON 
    a.id IN (m.account_from, m.account_to)
WHERE 
    u.email = 'Kaden.Gusikowski@gmail.com'
ORDER BY 
    a.type ASC,
    m.created_at ASC;
