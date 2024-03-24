
--6. SUBPROGRAM STOCAT INDEPENDENT CU 3 TIPURI DE COLECTII
CREATE OR REPLACE PROCEDURE INFO_CARTI_CATEGORII_IN_SECTIUNE IS
    -- TABLOU IMBRICAT cu numele sectiunilor
    TYPE tabel_imbricat_sectiune IS TABLE OF SECTIUNE%ROWTYPE;
   
    t_sectiune tabel_imbricat_sectiune := tabel_imbricat_sectiune();
    
    -- VECTOR pentru numele categoriilor (estimativ stim ca nu ar putea fi mai mult de 20 de categorii intr-o sectiune)
    TYPE vector_categorii IS VARRAY(20) OF CATEGORIE%ROWTYPE;
    v_categorii vector_categorii;
    
    -- TABLOU INDEXAT pentru titlurile cartilor
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
    END INFO_CARTI_CATEGORII_IN_SECTIUNE;
/

--Apelarea subprogramului
BEGIN
    INFO_CARTI_CATEGORII_IN_SECTIUNE;
END;
/

