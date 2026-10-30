-- Лабораторная работа №2: Создание запросов (PostgreSQL)
-- Вариант 6. Склады и размещение товаров.
-- Источник структуры таблиц: https://github.com/mapbke/lab1
-- Запускать в базе warehouse_lab_v6 после выполнения первой лабораторной.
-- Таблицы warehouses и placements остаются неизменными.

-- 1. Номера складов, которые не получали товар в сентябре.
-- Год не ограничен, поскольку он не указан в условии.
SELECT w.warehouse_id
FROM warehouses AS w
WHERE NOT EXISTS (
    SELECT 1
    FROM placements AS p
    WHERE p.warehouse_id = w.warehouse_id
      AND EXTRACT(MONTH FROM p.shipment_date) = 9
      AND p.is_received = TRUE
)
ORDER BY w.warehouse_id;


-- 2. Все склады Москвы с вакантной должностью заведующего.
SELECT w.*
FROM warehouses AS w
WHERE w.address ILIKE 'Москва,%'
  AND (w.manager_name IS NULL OR BTRIM(w.manager_name) = '')
ORDER BY w.warehouse_id;


-- 3. Создать таблицу из результата запроса 1,
-- добавив адрес, вместимость и заведующего (он нужен в пункте 6).
DROP TABLE IF EXISTS lab2_warehouses;

CREATE TABLE lab2_warehouses AS
SELECT
    w.warehouse_id,
    w.address,
    w.capacity,
    w.manager_name
FROM warehouses AS w
WHERE NOT EXISTS (
    SELECT 1
    FROM placements AS p
    WHERE p.warehouse_id = w.warehouse_id
      AND EXTRACT(MONTH FROM p.shipment_date) = 9
      AND p.is_received = TRUE
);


-- 4. Добавить в созданную таблицу склады, расположенные не в Москве.
-- NOT EXISTS защищает от дублирования складов из пункта 3.
INSERT INTO lab2_warehouses (warehouse_id, address, capacity, manager_name)
SELECT
    w.warehouse_id,
    w.address,
    w.capacity,
    w.manager_name
FROM warehouses AS w
WHERE w.address NOT ILIKE 'Москва,%'
  AND NOT EXISTS (
      SELECT 1
      FROM lab2_warehouses AS l
      WHERE l.warehouse_id = w.warehouse_id
  );


-- 5. Увеличить вместимость в 3 раза у складов с чётными номерами.
UPDATE lab2_warehouses
SET capacity = capacity * 3
WHERE MOD(warehouse_id, 2) = 0;


-- 6. Удалить из созданной таблицы склады без заведующего.
DELETE FROM lab2_warehouses
WHERE manager_name IS NULL OR BTRIM(manager_name) = '';


-- Проверка результата пунктов 3–6.
SELECT *
FROM lab2_warehouses
ORDER BY warehouse_id;


-- 7. Суммарный вес товара, отгруженного на каждый склад за 2008 год.
-- LEFT JOIN включает и склады без отгрузок; для них вес равен 0.
SELECT
    w.warehouse_id,
    w.address,
    COALESCE(SUM(p.weight_kg), 0) AS total_weight_kg
FROM warehouses AS w
LEFT JOIN placements AS p
    ON p.warehouse_id = w.warehouse_id
   AND p.shipment_date >= DATE '2008-01-01'
   AND p.shipment_date < DATE '2009-01-01'
GROUP BY w.warehouse_id, w.address
ORDER BY w.warehouse_id;
