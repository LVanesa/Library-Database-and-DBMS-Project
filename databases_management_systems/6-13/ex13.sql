CREATE OR REPLACE PACKAGE proiectSGBD AS

    PROCEDURE exercitiul6;
    PROCEDURE exercitiul7(v_nume_cititor cititor.nume%TYPE);
    FUNCTION exercitiul8(v_nume_editura editura.nume_editura%TYPE) RETURN VARCHAR2;
    PROCEDURE exercitiul9(p_nume_autor VARCHAR2);

END proiectSGBD;
/
CREATE OR REPLACE PACKAGE BODY proiectSGBD AS
    PROCEDURE exercitiul6 IS
    
    TYPE tabel_imbricat_sectiune IS TABLE OF SECTIUNE%ROWTYPE;
   
    t_sectiune tabel_imbricat_sectiune := tabel_imbricat_sectiune();
    
    TYPE vector_categorii IS VARRAY(20) OF CATEGORIE%ROWTYPE;
    v_categorii vector_categorii;
    
    TYPE tabel_indexat_carti IS TABLE OF CARTE.titlu%TYPE INDEX BY PLS_INTEGER;
    t_carti tabel_indexat_carti;
    
    BEGIN
        SELECT *
        BULK COLLECT INTO t_sectiune
        FROM SECTIUNE;
        
        FOR i IN 1..t_sectiune.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------');
            SELECT *
            BULK COLLECT INTO v_categorii
            FROM CATEGORIE
            WHERE ID_SECTIUNE = t_sectiune(i).id_sectiune;
            
            IF v_categorii.COUNT > 0 THEN
                DBMS_OUTPUT.PUT_LINE(i||'. SECTIUNEA ' || t_sectiune(i).nume_sectiune || ' contine urmatoarele categorii: ');
                FOR j IN 1..v_categorii.COUNT LOOP
                    SELECT titlu
                    BULK COLLECT INTO t_carti
                    FROM CARTE
                    WHERE ID_CATEGORIE = v_categorii(j).id_categorie;
                    
                    IF t_carti.COUNT > 0 THEN
                        DBMS_OUTPUT.PUT_LINE('      ' || j || '. CATEGORIA ' || UPPER( v_categorii(j).nume_categorie) || ' contine urmatoarele carti: ');
                        FOR k IN 1..t_carti.COUNT LOOP
                            DBMS_OUTPUT.PUT_LINE('                  --> CARTE: ' || t_carti(k));
                        END LOOP;
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('      ' || j || '. CATEGORIA ' || UPPER(v_categorii(j).nume_categorie) || ' nu contine nicio carte inca! ');
                    END IF;
                END LOOP;
            ELSE
                DBMS_OUTPUT.PUT_LINE(i||'. SECTIUNEA '|| UPPER(t_sectiune(i).nume_sectiune) || ' nu contine nicio categorie inca! ');
            END IF;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE(' ');
        
    END exercitiul6;
    
    PROCEDURE exercitiul7 (v_nume_cititor cititor.nume%TYPE) IS
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
    END exercitiul7;
    
    FUNCTION exercitiul8
    (v_nume_editura editura.nume_editura%TYPE)
    RETURN VARCHAR2
    IS
        v_lista_carti VARCHAR2(4000);
        v_nr_edituri NUMBER;
        custom_no_data_found exception;
        custom_too_many_rows exception;
        fara_exemplare_deteriorate exception;
    
    BEGIN
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
                       ', Numar Exemplare Deteriorate: ' || i.numar_exemplare_deteriorate || CHR(10);
    END LOOP;

    --verific daca lista returnata este goala
    IF v_lista_carti IS NULL THEN
        RAISE fara_exemplare_deteriorate;
    END IF;
    
    RETURN v_lista_carti;
    
    EXCEPTION
        WHEN custom_no_data_found THEN
            DBMS_OUTPUT.PUT_LINE ('Nu exista editura in baza de date cu acest nume!');
            RETURN NULL;
        WHEN custom_too_many_rows THEN 
            DBMS_OUTPUT.PUT_LINE('Exista mai multe edituri in baza de date cu acest nume!');
            RETURN NULL;
        WHEN fara_exemplare_deteriorate THEN 
            DBMS_OUTPUT.PUT_LINE('Nu exista carti deteriorate pentru editura specificata.');
            RETURN NULL;
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('Alta Eroare!');
            DBMS_OUTPUT.PUT_LINE('Codul de Eroare asociat '||SQLCODE);
            DBMS_OUTPUT.PUT_LINE('Mesajul de Eroare asociat '||SQLERRM);
        RETURN NULL;
        
    END exercitiul8;
    
    PROCEDURE exercitiul9(
    p_nume_autor VARCHAR2
    ) AS
    TYPE info_carte IS RECORD (
        titlu VARCHAR2(100),
        categ VARCHAR2(100),
        nr_exemplare NUMBER,
        nr_imprumuturi NUMBER,
        popularitate NUMBER(10,2)
        --procentul pe care il reprezinta din nr total de imprumuturi
    );

    TYPE lista_carti_autor IS TABLE OF info_carte;
    
    v_id_autor AUTOR.id_autor%TYPE;
    v_total_imprumuturi NUMBER;
    v_rez lista_carti_autor := lista_carti_autor();
    nu_exista_carti exception;
    PRAGMA EXCEPTION_INIT (nu_exista_carti, -20002);
    
BEGIN

    SELECT id_autor INTO v_id_autor
    FROM AUTOR
    WHERE UPPER(nume) = UPPER(p_nume_autor);

    SELECT COUNT(*) INTO v_total_imprumuturi
    FROM IMPRUMUT;


    FOR rec IN (
        SELECT
            c.titlu,
            cg.nume_categorie,
            COUNT(DISTINCT e.id_exemplar) AS numar_exemplare,
            COUNT(i.id_imprumut) AS numar_imprumuturi,
            ROUND(COUNT(i.id_imprumut) * 100 / v_total_imprumuturi, 2)AS procentaj
        FROM SCRIERE s
        JOIN CARTE c ON s.id_carte = c.id_carte
        JOIN CATEGORIE cg ON c.id_categorie = cg.id_categorie
        LEFT JOIN EXEMPLAR e ON c.id_carte = e.id_carte
        LEFT JOIN IMPRUMUT i ON e.id_exemplar = i.id_exemplar
        WHERE s.id_autor = v_id_autor
        GROUP BY c.titlu, cg.nume_categorie
    ) LOOP
        
        v_rez.EXTEND;
        v_rez(v_rez.LAST).titlu := rec.titlu;
        v_rez(v_rez.LAST).categ := rec.nume_categorie;
        v_rez(v_rez.LAST).nr_exemplare := rec.numar_exemplare;
        v_rez(v_rez.LAST).nr_imprumuturi := rec.numar_imprumuturi;
        v_rez(v_rez.LAST).popularitate := rec.procentaj;
    END LOOP;
    
    IF v_rez.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Biblioteca nu detine nicio carte ce apartine acestui autor!');
    END IF;


    FOR i IN 1..v_rez.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Titlu: ' || v_rez(i).titlu || ', Categorie: ' || v_rez(i).categ || ', Num?r Exemplare: ' || v_rez(i).nr_exemplare || ', Num?r Împrumuturi: ' || v_rez(i).nr_imprumuturi || ', Procentaj Popularitate: ' || v_rez(i).popularitate || '%');
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu s-a gasit niciun autor cu numele dat in baza de date!');
    WHEN TOO_MANY_ROWS THEN 
        DBMS_OUTPUT.PUT_LINE ('In baza de date exista mai multi autori cu acest nume!');
    WHEN ZERO_DIVIDE THEN 
        DBMS_OUTPUT.PUT_LINE ('Nu exista imprumuturi inregistrare in baza de date! Procentajul nu poate fi calculat corect prin impartirea la 0!');
    WHEN nu_exista_carti THEN
        DBMS_OUTPUT.PUT_LINE('Codul de Eroare asociat '||SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mesajul de Eroare asociat '||SQLERRM);
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Alta Eroare!');
        DBMS_OUTPUT.PUT_LINE('Codul de Eroare asociat '||SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Mesajul de Eroare asociat '||SQLERRM);
    END exercitiul9;
END proiectSGBD;
/
BEGIN

    proiectSGBD.exercitiul6;
    proiectSGBD.exercitiul7('Iorgulescu');
    DBMS_OUTPUT.PUT_LINE('EDITURA Aramis');
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE(proiectSGBD.exercitiul8('Aramis'));
    DBMS_OUTPUT.NEW_LINE;
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Ionescu');
    proiectSGBD.exercitiul9('Ionescu');
END;
/ 
    
    