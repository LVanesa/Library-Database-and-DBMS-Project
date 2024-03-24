CREATE OR REPLACE PROCEDURE RaportAutor(
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
            TO_NUMBER(ROUND(COUNT(i.id_imprumut) * 100 / v_total_imprumuturi, 2), '999.99') AS procentaj
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
END RaportAutor;
/

--Pentru a putea testa tratarea tuturor exceptiilor am facut cateva inserari noi in tabelul autor:
INSERT INTO AUTOR (id_autor, nume, prenume, data_nastere) VALUES (seq_autor.NEXTVAL, 'Avram', 'Monica', TO_DATE('02-02-1982', 'DD-MM-YYYY'));
INSERT INTO AUTOR (id_autor, nume, prenume, data_nastere) VALUES (seq_autor.NEXTVAL, 'Popescu', 'Mihai', TO_DATE('02-02-1980', 'DD-MM-YYYY'));

select * from autor;

--PARTEA DE TESTARE

BEGIN
    --cazul fericit
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Ionescu');
    RaportAutor('Ionescu');
    DBMS_OUTPUT.NEW_LINE;
    --NO_DATA_FOUND
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Voicu');
    RaportAutor('Voicu');
    DBMS_OUTPUT.NEW_LINE;

    --TOO_MANY_ROWS
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Popescu');
    RaportAutor('Popescu');
    DBMS_OUTPUT.NEW_LINE;

    --nu_exista_carti exception
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Avram');
    RaportAutor('Avram');
    DBMS_OUTPUT.NEW_LINE;

END;
/


SELECT * FROM IMPRUMUT;
DELETE FROM IMPRUMUT;
ROLLBACK;

--zero_divide
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('NUMELE AUTORULUI: Ionescu');
    RaportAutor('Ionescu');
    DBMS_OUTPUT.NEW_LINE;
END;

/
