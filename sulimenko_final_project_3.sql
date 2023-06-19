WITH
step_1 AS (
    -- найдем активных студентов
    -- будем считать, что активный пользователь = усердный студент, который правильно решает 20 задач за текущий месяц
    -- текущим месяцем будем считать последним месяц (31 день), информация о котором хранится в peas 
    SELECT
        st_id,
        SUM(correct) as correct1
    FROM
        peas
    WHERE
        DATEDIFF(day, timest, (SELECT MAX(timest) FROM default.peas)) <  32 
    GROUP BY 
        st_id
    HAVING
        correct1 > 1 --20
    ),

step_2 AS (
    -- пропишем активный студент или нет, избавимся от задвоения в таблице studs и к какой группе относится  
    SELECT
        A.st_id,
        A.test_grp,
        CASE WHEN B.st_id='' THEN 0 ELSE 1 END AS activ
    FROM
        default.studs as A
    LEFT JOIN
        step_1 as B
    ON 
        A.st_id = B.st_id
    GROUP BY
        A.st_id,
        B.st_id,
        A.test_grp
    ),

step_3 AS (
    -- отфильтруем чеки последнего месяца
    SELECT 
        st_id,
        money,
        subject,
        sale_time
    FROM
        default.final_project_check
    WHERE
        DATEDIFF(day, sale_time, (SELECT MAX(timest) FROM default.peas)) <  32 
        AND DATEDIFF(day, sale_time, (SELECT MAX(timest) FROM default.peas)) > -1
    ),

step_4 AS (
    -- присоединим чеки ко всем студентам с признаком активности        
    SELECT
        A.st_id,
        A.test_grp,
        A.activ,
        B.money,
        B.subject
    FROM
        step_2 as A
    LEFT JOIN
        step_3 as B
    ON 
        A.st_id = B.st_id
    )
    

-- посчитаем метрики  
    
    
SELECT 
    test_grp,
   -- SUM(money) as all_profit,
   -- COUNT(DISTINCT st_id) as all_stud,
   -- SUM(CASE WHEN activ=0 THEN 0 ELSE money END) as sum_activ,
   -- COUNT(DISTINCT CASE WHEN activ=0 THEN null ELSE st_id END) as count_activ,
    
   -- COUNT(DISTINCT CASE WHEN money>0 THEN st_id ELSE null END) as count_stud_rev,
    
   -- COUNT(DISTINCT CASE WHEN money>0 and activ=1 THEN st_id ELSE null END) as count_activ_stud_rev,
    
   -- COUNT(DISTINCT CASE WHEN money>0 and activ=1 and subject = 'Math' THEN st_id ELSE null END) as count_actstud__math,
    
   -- COUNT(DISTINCT CASE WHEN money>0 and subject = 'Math' THEN st_id ELSE null END) as count_stud__math
   SUM(money) / COUNT(DISTINCT st_id) as ARPU,
   SUM(CASE WHEN activ=0 THEN 0 ELSE money END) / COUNT(DISTINCT CASE WHEN activ=0 THEN null ELSE st_id END) as ARPAU,
   COUNT(DISTINCT CASE WHEN money>0 THEN st_id ELSE null END) / COUNT(DISTINCT st_id) as CR,
   COUNT(DISTINCT CASE WHEN money>0 and activ=1 THEN st_id ELSE null END) / COUNT(DISTINCT CASE WHEN activ=0 THEN null ELSE st_id END) as CR_activ,
   COUNT(DISTINCT CASE WHEN money>0 and activ=1 and subject = 'Math' THEN st_id ELSE null END) / COUNT(DISTINCT CASE WHEN money>0 and subject = 'Math' THEN st_id ELSE null END) as CR_math

FROM
    step_4
GROUP BY
    test_grp