--1-Delivery Performance & Customer Review 

/*
CTE 1: order_aggregates
الهدف: تجميع كل الفلوس (سعر المنتجات والشحن) لكل طلبية.
لأن الطلبية الواحدة ممكن تحتوي على أكتر من منتج (أكتر من صف في جدول order_items).
*/
WITH order_aggregates AS (
    SELECT
        order_id,
        SUM(price) AS total_items_value,
        SUM(freight_value) AS total_freight_value
    FROM
        olist_order_items_dataset
    GROUP BY
        order_id
),

/*
CTE 2: order_reviews_agg
الهدف: نجيب التقييم (review_score) لكل طلبية.
بنستخدم AVG() احتياطي لو فيه أي طلب له أكتر من تقييم (نادر بس ممكن).
*/
order_reviews_agg AS (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM
        olist_order_reviews_dataset
    GROUP BY
        order_id
)

/*
Main Query: بناء الـ Fact Table
الهدف: دمج كل الجداول الرئيسية (الطلبات، العملاء) مع الجداول اللي جهزناها (الفلوس، التقييمات)
وحساب أهم مقاييس الوقت (Time Metrics).
*/
SELECT
    o.order_id,
    o.order_status,
    c.customer_unique_id, -- ده الـ ID الحقيقي للعميل
    c.customer_state,     -- أهم Dimension جغرافي هنستخدمه
    
    -- Time Stamps (مهمة للـ Time Intelligence في Power BI)
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Logistics KPIs (أهم مقاييس في التحليل ده)
    -- ملاحظة: DATEDIFF بيختلف من نظام SQL للتاني. ده مثال (MySQL/SQL Server)
    -- (MySQL)
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_time_days,
    -- (SQL Server)
    -- DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_time_days,
    
    -- (MySQL)
    DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date) AS delivery_diff_days, -- (موجب = وصل بدري, سالب = وصل متأخر)
    -- (SQL Server)
    -- DATEDIFF(DAY, o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delivery_diff_days,

    -- Financial KPIs
    COALESCE(agg.total_items_value, 0) AS total_items_value,
    COALESCE(agg.total_freight_value, 0) AS total_freight_value,
    
    -- Satisfaction KPI
    rev.review_score
    
FROM
    olist_orders_dataset AS o

-- Join Customer Info (عشان نجيب الولاية)
LEFT JOIN
    olist_customers_dataset AS c ON o.customer_id = c.customer_id

-- Join Financial Aggregates
LEFT JOIN
    order_aggregates AS agg ON o.order_id = agg.order_id
    
-- Join Review Scores
LEFT JOIN
    order_reviews_agg AS rev ON o.order_id = rev.order_id

WHERE
    o.order_status = 'delivered'; -- (الأهم) إحنا بنحلل فقط الطلبات اللي اتسلمت فعلاً











--2-CustomerRFM




/*
الهدف: حساب RFM (Recency, Frequency, Monetary) لكل عميل فريد.
ده هيساعدنا نقسم العملاء لشرائح (Segments) ونفهم مين هم أفضل عملائنا.
*/

-- الخطوة 1: تحديد "اليوم" (آخر تاريخ في الداتا كلها) عشان نحسب منه الـ Recency
-- ده مهم جداً عشان تكون الحسابات ثابتة.
-- (ملاحظة: DATEDIFF تختلف بين SQL Server و MySQL. الكود ده بيستخدم صيغة MySQL/PostgreSQL)
WITH 
latest_date AS (
    -- بنجيب آخر تاريخ شراء في الداتا كلها عشان نعتبره "النهاردة"
    SELECT MAX(order_purchase_timestamp) AS max_purchase_date
    FROM olist_orders_dataset
),

-- الخطوة 2: تجميع بيانات الدفع والطلبات لكل عميل
customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        p.payment_value
    FROM
        olist_orders_dataset AS o
    JOIN
        olist_customers_dataset AS c ON o.customer_id = c.customer_id
    JOIN
        olist_order_payments_dataset AS p ON o.order_id = p.order_id
    WHERE
        o.order_status = 'delivered' -- بنركز على الطلبات المكتملة اللي جابت فلوس
),

-- الخطوة 3: تجميع المدفوعات على مستوى الطلب (لأن الطلب ممكن يتدفع بكذا طريقة)
order_level_payments AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        SUM(payment_value) AS order_total_payment
    FROM
        customer_orders
    GROUP BY
        customer_unique_id, order_id, order_purchase_timestamp
)

-- الخطوة 4: حساب الـ R, F, M لكل عميل فريد
SELECT
    rfm.customer_unique_id,
    
    -- Recency (R): كام يوم عدى من آخر مرة اشترى؟
    -- (MySQL/PostgreSQL)
    DATEDIFF((SELECT max_purchase_date FROM latest_date), MAX(rfm.order_purchase_timestamp)) AS recency_days,
    -- (SQL Server use: DATEDIFF(DAY, MAX(rfm.order_purchase_timestamp), (SELECT max_purchase_date FROM latest_date)))
    
    -- Frequency (F): اشترى كام مرة؟
    COUNT(DISTINCT rfm.order_id) AS frequency,
    
    -- Monetary (M): إجمالي اللي دفعه
    SUM(rfm.order_total_payment) AS monetary_value
    
FROM
    order_level_payments AS rfm
GROUP BY
    rfm.customer_unique_id;













--3-ProductSellerPerformance

/*
الهدف: تجميع أداء المبيعات والتقييمات لكل (منتج + بائع)
عشان نعرف مين البائعين الكويسين ومين اللي بيبيع منتجات عليها مشاكل.
*/

-- الخطوة 1: تجميع المقاييس الأساسية على مستوى الطلب (التقييم ووقت التوصيل)
WITH order_kpis AS (
    SELECT
        o.order_id,
        r.review_score,
        -- (MySQL/PostgreSQL)
        DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_time_days
        -- (SQL Server use: DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date))
    FROM
        olist_orders_dataset AS o
    LEFT JOIN
        olist_order_reviews_dataset AS r ON o.order_id = r.order_id
    WHERE
        o.order_status = 'delivered'
),

-- الخطوة 2: تجميع كل حاجة على مستوى المنتج والبائع
product_seller_performance AS (
    SELECT
        items.product_id,
        items.seller_id,
        
        -- Sales KPIs
        SUM(items.price) AS total_revenue,
        COUNT(DISTINCT items.order_id) AS total_orders,
        COUNT(items.order_item_id) AS total_items_sold,
        
        -- KPIs from joined table
        AVG(kpi.review_score) AS avg_review_score,
        AVG(kpi.delivery_time_days) AS avg_delivery_time
        
    FROM
        olist_order_items_dataset AS items
    
    -- نستخدم INNER JOIN هنا عشان نركز بس على الطلبات اللي اتسلمت وليها بيانات
    JOIN
        order_kpis AS kpi ON items.order_id = kpi.order_id
        
    GROUP BY
        items.product_id,
        items.seller_id
)

-- الخطوة 3: إضافة أسماء فئات المنتجات (Product Category)
SELECT
    psp.*,
    -- بنستخدم ملف الترجمة عشان الأسماء تكون بالانجليزي
    COALESCE(trans.product_category_name_english, prod.product_category_name) AS product_category
FROM
    product_seller_performance AS psp
LEFT JOIN
    olist_products_dataset AS prod ON psp.product_id = prod.product_id
LEFT JOIN
    -- (ده اسم الجدول اللي فيه ترجمة الفئات)
    product_category_name_translation AS trans ON prod.product_category_name = trans.product_category_name;










--4-MonthlyMetrics



/*
الهدف: تجميع الإيرادات والطلبات شهرياً، مع تقسيمها حسب طريقة الدفع.
ده هيورينا نمو البيزنس (Revenue Growth) وتفضيلات الدفع للعملاء.
*/
SELECT
    -- (MySQL/PostgreSQL)
    -- بنحول التاريخ لأول يوم في الشهر عشان Power BI يفهمه صح كـ Date Hierarchy
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS order_month,
    
    -- (SQL Server)
    -- FORMAT(o.order_purchase_timestamp, 'yyyy-MM-01') AS order_month,

    -- (ملاحظة: فيه طلبات ليها أكتر من طريقة دفع، بس هنا هناخد الطريقة الأساسية)
    p.payment_type,
    
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.payment_value) AS total_revenue
    
FROM
    olist_orders_dataset AS o
JOIN
    olist_order_payments_dataset AS p ON o.order_id = p.order_id
    
WHERE
    -- بنستبعد الطلبات اللي اتلغت أو اللي متعملتش من الأساس
    o.order_status NOT IN ('unavailable', 'canceled', 'created')
    
GROUP BY
    order_month,
    p.payment_type
    
ORDER BY
    order_month ASC;