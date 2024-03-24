--7.
CREATE OR REPLACE PROCEDURE info_imprumuturi_cititor (v_nume_cititor IN cititor.nume%TYPE) IS
    -- Cursor neparametrizat care preia cititorii al caror nume se potriveste numele dat ca parametru subprogramului
    CURSOR c_cititor IS
        SELECT c.nume, c.prenume, c.id_cititor
        FROM CITITOR C 
        WHERE UPPER(C.NUME) = UPPER(v_nume_cititor);
    
    -- Cursor parametrizat care preia informatii despre imprumuturile fiecarui cititor dat ca parametru
    CURSOR c_imprumuturi(v_id_cititor cititor.id_cititor%TYPE) IS
        SELECT i.id_imprumut, c.titlu, i.data_imprumut, i.data_returnare, e.stare
        FROM IMPRUMUT i
        JOIN EXEMPLAR e ON i.id_exemplar = e.id_exemplar
        JOIN CARTE c ON e.id_carte = c.id_carte
        WHERE i.id_cititor = v_id_cititor;

    v_exista_cititori BOOLEAN := FALSE;
    v_nr_imprumuturi NUMBER;

BEGIN
    FOR i IN c_cititor LOOP
        v_exista_cititori := TRUE;
        
        DBMS_OUTPUT.PUT_LINE('------------------------');
        DBMS_OUTPUT.PUT_LINE(i.nume || ' ' || i.prenume);

        v_nr_imprumuturi := 0;

        FOR j IN c_imprumuturi(i.id_cititor) LOOP
            v_nr_imprumuturi := v_nr_imprumuturi + 1;
            
            DBMS_OUTPUT.PUT_LINE(v_nr_imprumuturi || '. Imprumutul cu ID-ul ' || j.id_imprumut || ': ' || j.titlu 
              || ', Data Imprumutului: ' || TO_CHAR(j.data_imprumut, 'DD-MON-YYYY')
              || ', Data Returnarii: ' || NVL(TO_CHAR(j.data_returnare, 'DD-MON-YYYY'), '-') 
              || ', Starea: ' || j.stare);
        END LOOP;
        IF v_nr_imprumuturi > 0 THEN 
            DBMS_OUTPUT.PUT_LINE('Total imprumuturi: ' || v_nr_imprumuturi);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Cititorul nu are imprumuturi!');
        END IF;
    END LOOP;
    IF NOT v_exista_cititori THEN 
        DBMS_OUTPUT.PUT_LINE('Nu s-a gasit niciun cititor in baza de date cu acest nume!');
    END IF;
END info_imprumuturi_cititor;
/


--Am mai inserat niste date in tabele ca sa putem testa mai multe variante
INSERT INTO CITITOR (id_cititor, nume, prenume, email, nr_telefon, data_inscriere) VALUES (seq_cititor.NEXTVAL, 'Iorgulescu', 'Alexandra', 'alexandra.iorg@gmail.com', '0721122334', TO_DATE('2010-03-12', 'YYYY-MM-DD'));
INSERT INTO IMPRUMUT (id_imprumut, id_exemplar, id_cititor, data_imprumut)
VALUES (seq_imprumut.NEXTVAL, 7, 12, TO_DATE('2024-01-8', 'YYYY-MM-DD'));
rollback;
/
--verificam pentru mai multi cititori cu acest nume
begin
    info_imprumuturi_cititor('Iorgulescu');
end;
/
--verificam pentru un cititor care nu are imprumuturi
begin
    info_imprumuturi_cititor('Ionascu');
end;
/
--verificam pentru un cititor care nu exista in baza de date
begin
    info_imprumuturi_cititor('Voicu');
end;
/