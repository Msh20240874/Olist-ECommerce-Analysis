SELECT
    o.order_id,
    
    -- Our Target Variable (الهدف)
    r.review_score,
    
    -- Time Features (متغيرات الوقت)
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Financial Features (متغيرات مالية)
    oi.price,
    oi.freight_value,
    
    -- Product Features (متغيرات المنتج)
    p.product_category_name,
    
    -- Location Features (متغيرات المكان)
    c.customer_state,
    s.seller_state

FROM
    olist_orders_dataset AS o
JOIN
    olist_order_reviews_dataset AS r ON o.order_id = r.order_id
JOIN
    olist_order_items_dataset AS oi ON o.order_id = oi.order_id
JOIN
    olist_products_dataset AS p ON oi.product_id = p.product_id
JOIN
    olist_customers_dataset AS c ON o.customer_id = c.customer_id
JOIN
    olist_sellers_dataset AS s ON oi.seller_id = s.seller_id
WHERE
    o.order_status = 'delivered' -- (الأهم) إحنا بنحلل فقط الطلبات اللي اتسلمت
    AND r.review_score IS NOT NULL; -- نتأكد إن فيه تقييم