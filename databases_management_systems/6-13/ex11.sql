CREATE OR REPLACE TRIGGER data_retur_incorecta
BEFORE UPDATE OF data_returnare ON imprumut
FOR EACH ROW
BEGIN
    IF(:NEW.data_returnare > SYSDATE)
        THEN RAISE_APPLICATION_ERROR(-20000, 
        'Ati introdus o valoare invalida pentru data returnarii! 
        Aceasta nu poate fi mai mare decat data zilei curente.');
    END IF;
END;
/
UPDATE IMPRUMUT 
SET DATA_RETURNARE = SYSDATE-1 
WHERE id_imprumut = 15;

/
alter trigger trig_ex2 disable;

ALTER TRIGGER data_retur_incorecta DISABLE;



