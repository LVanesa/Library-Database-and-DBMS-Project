CREATE OR REPLACE TRIGGER modificare_BD
BEFORE CREATE OR ALTER OR DROP
ON SCHEMA
DECLARE
    ora_inceput NUMBER := 8;
    ora_sfarsit NUMBER := 15;
    zi_nelucratoare NUMBER := 1; -- duminica
BEGIN
    IF TO_NUMBER(TO_CHAR(SYSDATE, 'D')) = zi_nelucratoare OR
       TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) NOT BETWEEN ora_inceput AND ora_sfarsit
    THEN
        RAISE_APPLICATION_ERROR(-20001, 'Programul de lucru s-a terminat! Se pot face modificari in baza de date doar in intervalul 08.00-16.00');
    END IF;
END;

/
--testare create
create table cititor_aux as select * from cititor;
--testare alter
alter table cititor drop column data_inscriere;
--testare drop
drop table cititor_aux;
alter trigger modificare_BD disable;

rollback;
select * from cititor;

