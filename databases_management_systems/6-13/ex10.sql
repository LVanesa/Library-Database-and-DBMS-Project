CREATE OR REPLACE TRIGGER program_biblioteca
    BEFORE INSERT OR DELETE OR UPDATE ON IMPRUMUT
BEGIN
    IF (TO_CHAR(SYSDATE, 'D') = 1) OR
       ((TO_CHAR(SYSDATE, 'D') = 7) AND TO_CHAR(SYSDATE, 'HH24') NOT BETWEEN 9 AND 12) OR
       (TO_CHAR(SYSDATE, 'HH24') NOT BETWEEN 8 AND 15)
    THEN 
        DBMS_OUTPUT.PUT_LINE('PROGRAM CU PUBLICUL');
        DBMS_OUTPUT.PUT_LINE('Luni-Vineri: 08.00-16.00');
        DBMS_OUTPUT.PUT_LINE('Sambata: 09.00-13.00');
        DBMS_OUTPUT.PUT_LINE('Duminica: INCHIS!');
        IF INSERTING THEN 
            RAISE_APPLICATION_ERROR(-20001, 'Nu se pot face imprumuturi in afara programului cu publicul!'); 
        ELSIF DELETING THEN 
            RAISE_APPLICATION_ERROR(-20002, 'Nu se pot anula imprumuturi in afara programului cu publicul!'); 
        ELSE  
            RAISE_APPLICATION_ERROR(-20003, 'Nu se pot returna carti in afara programului cu publicul!'); 
        END IF; 
    END IF; 
END;
/

--verificam INSERT
INSERT INTO IMPRUMUT (id_imprumut, id_exemplar, id_cititor, data_imprumut)
VALUES (seq_imprumut.NEXTVAL, 35, 4, TO_DATE('2023-04-23', 'YYYY-MM-DD'));
ROLLBACK;

--verificam UPDATE
UPDATE IMPRUMUT SET DATA_RETURNARE = SYSDATE WHERE id_imprumut = 15;
--verificam DELETE
DELETE FROM IMPRUMUT WHERE id_imprumut = 1;

SELECT TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:MI') AS data_si_ora FROM dual;

alter trigger program_biblioteca disable;
