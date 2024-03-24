
---VARIANTA NEOFICIALA CU PRAGMA!!
CREATE OR REPLACE FUNCTION CentralizareCariDeteriorateEditura(
    v_nume_editura IN VARCHAR2
) RETURN VARCHAR2
IS
    v_lista_carti VARCHAR2(4000);
BEGIN
    -- Verific?m existen?a editurii �n baza de date
    DECLARE
        v_nr_edituri NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_nr_edituri
        FROM editura
        WHERE nume_editura = v_nume_editura;

        IF v_nr_edituri = 0 THEN 
            RAISE_APPLICATION_ERROR(-20000, 'Nu exist? editur? �n baza de date cu acest nume!');
        ELSIF v_nr_edituri > 1 THEN 
            RAISE_APPLICATION_ERROR(-20001, 'Exist? mai multe edituri �n baza de date cu acest nume');
        END IF;
    END;

    -- Centralizarea c?r?ilor deteriorate pentru editura specificat?
    FOR i IN (
        SELECT c.titlu, c.an_publicare, COUNT(e.id_exemplar) AS numar_exemplare_deteriorate
        FROM CARTE c
        JOIN EXEMPLAR e ON c.id_carte = e.id_carte
        JOIN EDITURA ed ON c.id_editura = ed.id_editura
        WHERE ed.nume_editura = v_nume_editura AND e.stare = UPPER('deteriorata')
        GROUP BY c.titlu, c.an_publicare
    )
    LOOP
        v_lista_carti := v_lista_carti || 'Titlu: ' || i.titlu || ', An Publicare: ' || i.an_publicare ||
                       ', Num?r Exemplare Deteriorate: ' || i.numar_exemplare_deteriorate || CHR(10);
    END LOOP;

    -- Tratarea cazului �n care nu exist? c?r?i deteriorate pentru editura specificat?
    IF v_lista_carti IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nu exist? c?r?i deteriorate pentru editura specificat?.');
    END IF;
    RETURN v_lista_carti;
END CentralizareCariDeteriorateEditura;
/
DECLARE
    exceptie1 EXCEPTION;
    exceptie2 EXCEPTION;
    exceptie3 EXCEPTION;
    PRAGMA EXCEPTION_INIT(exceptie1,-20000);
    PRAGMA EXCEPTION_INIT(exceptie2,-20001);
    PRAGMA EXCEPTION_INIT(exceptie3,-20002);

BEGIN
    DBMS_OUTPUT.PUT_LINE('EDITURA FaraCarti');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(CentralizareCariDeteriorateEditura('FaraCarti'));
EXCEPTION
    WHEN exceptie1 THEN
        DBMS_OUTPUT.PUT_LINE('Mesaj de eroare/exceptie: '||SQLERRM);
    WHEN exceptie2 THEN
        DBMS_OUTPUT.PUT_LINE('Mesaj de eroare/exceptie: '||SQLERRM);
    WHEN exceptie3 THEN
        DBMS_OUTPUT.PUT_LINE('Mesaj de eroare/exceptie: '||SQLERRM);
END;
/

---Varianta oficiala in care folosesc exceptii definite de utilizator
/
CREATE OR REPLACE FUNCTION NrExemplareDeteriorate(
    v_nume_editura IN VARCHAR2
) RETURN VARCHAR2
IS
    v_lista_carti VARCHAR2(4000);
    v_id_editura editura.id_editura%TYPE;
    custom_no_data_found exception;
    custom_too_many_rows exception;
    fara_exemplare_deteriorate exception;
    v_nr_edituri NUMBER;

BEGIN
        SELECT ID_EDITURA
        INTO v_id_editura
        FROM EDITURA
        WHERE nume_editura = v_nume_editura;
        
        SELECT COUNT(*)
        INTO v_nr_edituri
        FROM editura
        WHERE nume_editura = v_nume_editura;

        IF v_nr_edituri = 0 THEN 
            RAISE custom_no_data_found;
        ELSIF v_nr_edituri > 1 THEN 
            RAISE custom_too_many_rows;
        END IF;
  
    FOR i IN (
        SELECT c.titlu, c.an_publicare, COUNT(e.id_exemplar) AS numar_exemplare_deteriorate
        FROM CARTE c
        JOIN EXEMPLAR e ON c.id_carte = e.id_carte
        JOIN EDITURA ed ON c.id_editura = ed.id_editura
        WHERE ed.nume_editura = v_nume_editura AND e.stare = UPPER('deteriorata')
        GROUP BY c.titlu, c.an_publicare
    )
    LOOP
        v_lista_carti := v_lista_carti || 'Titlu: ' || i.titlu || ', An Publicare: ' || i.an_publicare ||
                       ', Num?r Exemplare Deteriorate: ' || i.numar_exemplare_deteriorate || CHR(10);
    END LOOP;

    -- Tratarea cazului �n care nu exist? c?r?i deteriorate pentru editura specificat?
    IF v_lista_carti IS NULL THEN
        RAISE fara_exemplare_deteriorate;
    END IF;
    RETURN v_lista_carti;
    EXCEPTION
        WHEN custom_no_data_found THEN
            DBMS_OUTPUT.PUT_LINE ('Nu exist? editur? �n baza de date cu acest nume!');
            RETURN NULL;
        WHEN custom_too_many_rows THEN 
            DBMS_OUTPUT.PUT_LINE('Exist? mai multe edituri �n baza de date cu acest nume');
            RETURN NULL;
        WHEN fara_exemplare_deteriorate THEN 
            DBMS_OUTPUT.PUT_LINE('Nu exist? c?r?i deteriorate pentru editura specificat?.');
            RETURN NULL;
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('Alta Eroare!');
            DBMS_OUTPUT.PUT_LINE('Codul de Eroare asociat '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mesajul de Eroare asociat '||SQLERRM);
        RETURN NULL;
END NrExemplareDeteriorate;
/

--cazul fericit
BEGIN
    DBMS_OUTPUT.PUT_LINE('EDITURA Aramis');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(NrExemplareDeteriorate('Aramis'));
END;
/
--custom_no_data_found exception
BEGIN
    DBMS_OUTPUT.PUT_LINE('EDITURA NUEXISTA');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(NrExemplareDeteriorate('NUEXISTA'));
END;
/
--custom_too_many_rows exception
BEGIN
    DBMS_OUTPUT.PUT_LINE('EDITURA NumeNou');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(NrExemplareDeteriorate('NumeNou'));
END;
/
--fara_exemplare_deteriorate exception
BEGIN
    DBMS_OUTPUT.PUT_LINE('EDITURA FaraCarti');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(NrExemplareDeteriorate('FaraCarti'));
END;
/




SELECT    
LINE, POSITION, TEXT 
FROM      USER_ERRORS 
WHERE     
NAME =UPPER('CentralizareCariDeteriorateEditura');

select * from editura;

INSERT INTO EDITURA (id_editura, nume_editura, email, nr_telefon) VALUES (6, 'NumeNou', 'contact@test.com', '0721122334');
INSERT INTO EDITURA (id_editura, nume_editura, email, nr_telefon) VALUES (7, 'NumeNou', 'contact@test.com', '0721122334');
INSERT INTO EDITURA (id_editura, nume_editura, email, nr_telefon) VALUES (8, 'FaraCarti', 'contact@test.com', '0721122334');





