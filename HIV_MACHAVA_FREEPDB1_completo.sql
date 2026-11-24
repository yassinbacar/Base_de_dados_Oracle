CREATE TABLESPACE ts_hiv_dados
  DATAFILE SIZE 100M
  AUTOEXTEND ON NEXT 10M MAXSIZE 1G;

CREATE TABLESPACE ts_hiv_idx
  DATAFILE SIZE 50M
  AUTOEXTEND ON NEXT 10M MAXSIZE 500M;

CREATE USER hiv_machava IDENTIFIED BY "Hiv#Machava2026"
  DEFAULT TABLESPACE ts_hiv_dados
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON ts_hiv_dados
  QUOTA UNLIMITED ON ts_hiv_idx;

GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, CREATE TRIGGER,
      CREATE PROCEDURE, CREATE VIEW TO hiv_machava;

-- Papeis por perfil profissional (RN18)
CREATE ROLE rl_medico;
CREATE ROLE rl_laboratorio;
CREATE ROLE rl_farmacia;
CREATE ROLE rl_administrador;

GRANT CREATE SESSION TO rl_medico, rl_laboratorio, rl_farmacia, rl_administrador;


-- Mudar para o esquema HIV_MACHAVA na FREEPDB1 (ajustar host/porta se necessario)
CONNECT hiv_machava/"Hiv#Machava2026"@//localhost:1521/FREEPDB1


-- #####################################################################
-- PARTE 2 - 02_sequencias_tabelas.sql  (executar como HIV_MACHAVA)
-- Requer Oracle 12c ou superior (DEFAULT ON NULL seq.NEXTVAL).
-- Cada restricao e comentada com a RN que a justifica.
-- #####################################################################

-- ---------------------------- SEQUENCIAS -----------------------------
CREATE SEQUENCE seq_paciente     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_profissional START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_teste        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_consulta     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_tipo_exame   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_exame        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_regime       START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_medicamento  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_prescricao   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_dispensa     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_busca        START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ------------------------------ TABELAS ------------------------------
-- PACIENTE (RN01, RN02, RN03, RN04, RN19, RN20)
CREATE TABLE paciente (
  id_paciente         NUMBER(10)    DEFAULT ON NULL seq_paciente.NEXTVAL,
  nid                 VARCHAR2(20)  NOT NULL,
  nome_completo       VARCHAR2(120) NOT NULL,
  data_nascimento     DATE          NOT NULL,
  sexo                CHAR(1)       NOT NULL,
  contacto_telefonico VARCHAR2(20),
  bairro              VARCHAR2(60)  NOT NULL,
  endereco            VARCHAR2(150),
  data_registo        DATE          DEFAULT SYSDATE NOT NULL,
  estado_paciente     VARCHAR2(15)  DEFAULT 'ACTIVO' NOT NULL,
  CONSTRAINT pk_paciente PRIMARY KEY (id_paciente)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT uk_paciente_nid UNIQUE (nid)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT ck_paciente_sexo CHECK (sexo IN ('M','F')),
  CONSTRAINT ck_paciente_estado CHECK
    (estado_paciente IN ('ACTIVO', 'ABANDONO', 'TRANSFERIDO', 'OBITO'))
) TABLESPACE ts_hiv_dados;

-- PROFISSIONAL_SAUDE (RN06, RN18, RN19)
CREATE TABLE profissional_saude (
  id_profissional NUMBER(6)     DEFAULT ON NULL seq_profissional.NEXTVAL,
  nome_completo   VARCHAR2(120) NOT NULL,
  categoria       VARCHAR2(20)  NOT NULL,
  num_registo     VARCHAR2(20)  NOT NULL,
  contacto        VARCHAR2(20),
  activo          CHAR(1)       DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_profissional PRIMARY KEY (id_profissional)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT uk_profissional_registo UNIQUE (num_registo)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT ck_profissional_categoria CHECK (categoria IN
    ('MEDICO', 'ENFERMEIRO', 'TECNICO_MEDICINA', 'TECNICO_LABORATORIO',
     'FARMACEUTICO', 'CONSELHEIRO')),
  CONSTRAINT ck_profissional_activo CHECK (activo IN ('S','N'))
) TABLESPACE ts_hiv_dados;

-- TIPO_EXAME (RN09, RN10)
CREATE TABLE tipo_exame (
  id_tipo_exame  NUMBER(4)    DEFAULT ON NULL seq_tipo_exame.NEXTVAL,
  designacao     VARCHAR2(80) NOT NULL,
  unidade_medida VARCHAR2(20),
  CONSTRAINT pk_tipo_exame PRIMARY KEY (id_tipo_exame)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT uk_tipo_exame_designacao UNIQUE (designacao)
    USING INDEX TABLESPACE ts_hiv_idx
) TABLESPACE ts_hiv_dados;

-- REGIME_TARV (RN11, RN12, RN13)
CREATE TABLE regime_tarv (
  id_regime        NUMBER(4)    DEFAULT ON NULL seq_regime.NEXTVAL,
  codigo           VARCHAR2(30) NOT NULL,
  descricao        VARCHAR2(150),
  linha_tratamento NUMBER(1)    NOT NULL,
  CONSTRAINT pk_regime PRIMARY KEY (id_regime)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT uk_regime_codigo UNIQUE (codigo)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT ck_regime_linha CHECK (linha_tratamento IN (1,2,3))
) TABLESPACE ts_hiv_dados;

-- MEDICAMENTO (RN11)
CREATE TABLE medicamento (
  id_medicamento     NUMBER(5)    DEFAULT ON NULL seq_medicamento.NEXTVAL,
  nome_generico      VARCHAR2(80) NOT NULL,
  dosagem            VARCHAR2(30) NOT NULL,
  forma_farmaceutica VARCHAR2(30),
  CONSTRAINT pk_medicamento PRIMARY KEY (id_medicamento)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT uk_medicamento UNIQUE (nome_generico, dosagem)
    USING INDEX TABLESPACE ts_hiv_idx
) TABLESPACE ts_hiv_dados;

-- TESTE_HIV (RN02, RN05, RN06)
CREATE TABLE teste_hiv (
  id_teste        NUMBER(10)   DEFAULT ON NULL seq_teste.NEXTVAL,
  id_paciente     NUMBER(10)   NOT NULL,
  id_profissional NUMBER(6)    NOT NULL,
  data_teste      DATE         NOT NULL,
  tipo_teste      VARCHAR2(15) NOT NULL,
  resultado       VARCHAR2(15) NOT NULL,
  CONSTRAINT pk_teste_hiv PRIMARY KEY (id_teste)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_teste_paciente FOREIGN KEY (id_paciente)
    REFERENCES paciente (id_paciente),
  CONSTRAINT fk_teste_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_saude (id_profissional),
  CONSTRAINT ck_teste_tipo CHECK
    (tipo_teste IN ('DIAGNOSTICO', 'CONFIRMACAO', 'REPETICAO')),
  CONSTRAINT ck_teste_resultado CHECK
    (resultado IN ('REACTIVO', 'NAO_REACTIVO', 'INDETERMINADO'))
) TABLESPACE ts_hiv_dados;

-- CONSULTA (RN06, RN07, RN08)
CREATE TABLE consulta (
  id_consulta           NUMBER(10)    DEFAULT ON NULL seq_consulta.NEXTVAL,
  id_paciente           NUMBER(10)    NOT NULL,
  id_profissional       NUMBER(6)     NOT NULL,
  data_consulta         DATE          NOT NULL,
  tipo_consulta         VARCHAR2(15)  NOT NULL,
  peso_kg               NUMBER(5,2),
  estadio_oms           NUMBER(1),
  observacoes           VARCHAR2(500),
  data_proxima_consulta DATE,
  CONSTRAINT pk_consulta PRIMARY KEY (id_consulta)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_consulta_paciente FOREIGN KEY (id_paciente)
    REFERENCES paciente (id_paciente),
  CONSTRAINT fk_consulta_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_saude (id_profissional),
  CONSTRAINT ck_consulta_tipo CHECK
    (tipo_consulta IN ('INICIAL', 'SEGUIMENTO', 'URGENCIA')),
  CONSTRAINT ck_consulta_peso CHECK (peso_kg > 0),
  CONSTRAINT ck_consulta_estadio CHECK (estadio_oms BETWEEN 1 AND 4),
  CONSTRAINT ck_consulta_proxima CHECK
    (data_proxima_consulta IS NULL OR data_proxima_consulta >= data_consulta)
) TABLESPACE ts_hiv_dados;

-- EXAME_LABORATORIAL (RN06, RN09, RN10)
CREATE TABLE exame_laboratorial (
  id_exame        NUMBER(10)    DEFAULT ON NULL seq_exame.NEXTVAL,
  id_paciente     NUMBER(10)    NOT NULL,
  id_tipo_exame   NUMBER(4)     NOT NULL,
  id_consulta     NUMBER(10),
  id_profissional NUMBER(6)     NOT NULL,
  data_colheita   DATE          NOT NULL,
  data_resultado  DATE,
  valor_resultado NUMBER(12,2),
  CONSTRAINT pk_exame PRIMARY KEY (id_exame)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_exame_paciente FOREIGN KEY (id_paciente)
    REFERENCES paciente (id_paciente),
  CONSTRAINT fk_exame_tipo FOREIGN KEY (id_tipo_exame)
    REFERENCES tipo_exame (id_tipo_exame),
  CONSTRAINT fk_exame_consulta FOREIGN KEY (id_consulta)
    REFERENCES consulta (id_consulta),
  CONSTRAINT fk_exame_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_saude (id_profissional),
  CONSTRAINT ck_exame_datas CHECK
    (data_resultado IS NULL OR data_resultado >= data_colheita),
  CONSTRAINT ck_exame_valor CHECK (valor_resultado >= 0)
) TABLESPACE ts_hiv_dados;

-- COMPOSICAO_REGIME (RN11) - entidade associativa
CREATE TABLE composicao_regime (
  id_regime      NUMBER(4)    NOT NULL,
  id_medicamento NUMBER(5)    NOT NULL,
  posologia      VARCHAR2(60) NOT NULL,
  CONSTRAINT pk_composicao PRIMARY KEY (id_regime, id_medicamento)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_composicao_regime FOREIGN KEY (id_regime)
    REFERENCES regime_tarv (id_regime),
  CONSTRAINT fk_composicao_medicamento FOREIGN KEY (id_medicamento)
    REFERENCES medicamento (id_medicamento)
) TABLESPACE ts_hiv_dados;

-- PRESCRICAO (RN06, RN12, RN13)
CREATE TABLE prescricao (
  id_prescricao NUMBER(10)   DEFAULT ON NULL seq_prescricao.NEXTVAL,
  id_consulta   NUMBER(10)   NOT NULL,
  id_regime     NUMBER(4)    NOT NULL,
  data_inicio   DATE         NOT NULL,
  data_fim      DATE,
  motivo        VARCHAR2(25) DEFAULT 'INICIO' NOT NULL,
  CONSTRAINT pk_prescricao PRIMARY KEY (id_prescricao)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_prescricao_consulta FOREIGN KEY (id_consulta)
    REFERENCES consulta (id_consulta),
  CONSTRAINT fk_prescricao_regime FOREIGN KEY (id_regime)
    REFERENCES regime_tarv (id_regime),
  CONSTRAINT ck_prescricao_datas CHECK
    (data_fim IS NULL OR data_fim >= data_inicio),
  CONSTRAINT ck_prescricao_motivo CHECK (motivo IN
    ('INICIO', 'FALENCIA_TERAPEUTICA', 'TOXICIDADE', 'INTOLERANCIA',
     'RUPTURA_STOCK', 'OUTRO'))
) TABLESPACE ts_hiv_dados;

-- DISPENSA (RN06, RN14, RN15, RN16)
CREATE TABLE dispensa (
  id_dispensa               NUMBER(10) DEFAULT ON NULL seq_dispensa.NEXTVAL,
  id_prescricao             NUMBER(10) NOT NULL,
  id_profissional           NUMBER(6)  NOT NULL,
  data_dispensa             DATE       NOT NULL,
  quantidade_dias           NUMBER(3)  NOT NULL,
  data_proximo_levantamento DATE       NOT NULL,
  CONSTRAINT pk_dispensa PRIMARY KEY (id_dispensa)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_dispensa_prescricao FOREIGN KEY (id_prescricao)
    REFERENCES prescricao (id_prescricao),
  CONSTRAINT fk_dispensa_profissional FOREIGN KEY (id_profissional)
    REFERENCES profissional_saude (id_profissional),
  CONSTRAINT ck_dispensa_dias CHECK (quantidade_dias > 0),
  CONSTRAINT ck_dispensa_proximo CHECK
    (data_proximo_levantamento > data_dispensa)
) TABLESPACE ts_hiv_dados;

-- BUSCA_ACTIVA (RN16, RN17, RN04)
CREATE TABLE busca_activa (
  id_busca           NUMBER(10)   DEFAULT ON NULL seq_busca.NEXTVAL,
  id_paciente        NUMBER(10)   NOT NULL,
  data_falta         DATE         NOT NULL,
  data_contacto      DATE         NOT NULL,
  meio_contacto      VARCHAR2(20) NOT NULL,
  agente_responsavel VARCHAR2(100),
  resultado          VARCHAR2(20) NOT NULL,
  CONSTRAINT pk_busca PRIMARY KEY (id_busca)
    USING INDEX TABLESPACE ts_hiv_idx,
  CONSTRAINT fk_busca_paciente FOREIGN KEY (id_paciente)
    REFERENCES paciente (id_paciente),
  CONSTRAINT ck_busca_datas CHECK (data_contacto >= data_falta),
  CONSTRAINT ck_busca_meio CHECK
    (meio_contacto IN ('TELEFONE', 'VISITA_DOMICILIAR', 'SMS')),
  CONSTRAINT ck_busca_resultado CHECK (resultado IN
    ('REGRESSOU', 'TRANSFERIDO', 'OBITO', 'NAO_LOCALIZADO', 'RECUSOU'))
) TABLESPACE ts_hiv_dados;

-- --------------------------- COMENTARIOS -----------------------------
COMMENT ON TABLE paciente IS 'Utente registado no servico de HIV (RN01-RN04)';
COMMENT ON TABLE profissional_saude IS 'Profissionais de saude (RN06)';
COMMENT ON TABLE teste_hiv IS 'Testes de HIV realizados (RN05)';
COMMENT ON TABLE consulta IS 'Consultas clinicas (RN07, RN08)';
COMMENT ON TABLE tipo_exame IS 'Catalogo de tipos de exame (RN09)';
COMMENT ON TABLE exame_laboratorial IS 'Exames e resultados (RN09, RN10)';
COMMENT ON TABLE regime_tarv IS 'Regimes de tratamento antirretroviral (RN11)';
COMMENT ON TABLE medicamento IS 'Medicamentos antirretrovirais (RN11)';
COMMENT ON TABLE composicao_regime IS 'Medicamentos de cada regime (RN11)';
COMMENT ON TABLE prescricao IS 'Prescricao de regimes (RN12, RN13)';
COMMENT ON TABLE dispensa IS 'Levantamentos na farmacia (RN14, RN15)';
COMMENT ON TABLE busca_activa IS 'Busca activa de faltosos (RN16, RN17)';


-- #####################################################################
-- PARTE 3 - 03_indices.sql  (executar como HIV_MACHAVA)
-- PK e UK ja criam indices. Aqui: indices nas chaves estrangeiras
-- (o Oracle nao os cria automaticamente) e nas pesquisas frequentes.
-- RNF04 (desempenho), RN07, RN16
-- #####################################################################

CREATE INDEX ix_paciente_nome
  ON paciente (UPPER(nome_completo))
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_paciente_estado
  ON paciente (estado_paciente)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_teste_paciente
  ON teste_hiv (id_paciente, resultado)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_teste_prof
  ON teste_hiv (id_profissional)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_consulta_pac_data
  ON consulta (id_paciente, data_consulta)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_consulta_prof
  ON consulta (id_profissional)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_exame_pac_tipo
  ON exame_laboratorial (id_paciente, id_tipo_exame, data_colheita)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_exame_consulta
  ON exame_laboratorial (id_consulta)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_exame_prof
  ON exame_laboratorial (id_profissional)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_composicao_med
  ON composicao_regime (id_medicamento)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_prescricao_cons
  ON prescricao (id_consulta)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_prescricao_regime
  ON prescricao (id_regime)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_dispensa_presc
  ON dispensa (id_prescricao)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_dispensa_prof
  ON dispensa (id_profissional)
  TABLESPACE ts_hiv_idx;
CREATE INDEX ix_dispensa_proximo
  ON dispensa (data_proximo_levantamento)
  TABLESPACE ts_hiv_idx;

CREATE INDEX ix_busca_paciente
  ON busca_activa (id_paciente, data_falta)
  TABLESPACE ts_hiv_idx;


-- #####################################################################
-- PARTE 4 - 04_triggers.sql  (executar como HIV_MACHAVA)
-- Regras de negocio que o CHECK declarativo nao consegue expressar.
-- #####################################################################

-- RN20: data de nascimento nao pode ser futura
-- (o Oracle nao admite SYSDATE em restricoes CHECK)
CREATE OR REPLACE TRIGGER trg_paciente_data_nasc
BEFORE INSERT OR UPDATE OF data_nascimento ON paciente
FOR EACH ROW
BEGIN
  IF :NEW.data_nascimento > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20001,
      'RN20: a data de nascimento nao pode ser posterior a data actual.');
  END IF;
END trg_paciente_data_nasc;
/

-- RN02: so ha consulta de pacientes com teste REACTIVO registado
CREATE OR REPLACE TRIGGER trg_consulta_teste_reactivo
BEFORE INSERT ON consulta
FOR EACH ROW
DECLARE
  v_n NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_n
    FROM teste_hiv
   WHERE id_paciente = :NEW.id_paciente
     AND resultado = 'REACTIVO';
  IF v_n = 0 THEN
    RAISE_APPLICATION_ERROR(-20002,
      'RN02: o paciente nao tem teste de HIV REACTIVO registado.');
  END IF;
END trg_consulta_teste_reactivo;
/

-- RN12: um paciente so pode ter uma prescricao activa (data_fim nula).
-- Trigger composto: evita o erro ORA-04091 (tabela em mutacao), pois a
-- verificacao e feita no AFTER STATEMENT.
CREATE OR REPLACE TRIGGER trg_prescricao_unica_activa
FOR INSERT OR UPDATE OF data_fim, id_consulta ON prescricao
COMPOUND TRIGGER
  TYPE t_ids IS TABLE OF prescricao.id_consulta%TYPE INDEX BY PLS_INTEGER;
  g_ids t_ids;

  BEFORE EACH ROW IS
  BEGIN
    g_ids(g_ids.COUNT + 1) := :NEW.id_consulta;
  END BEFORE EACH ROW;

  AFTER STATEMENT IS
    v_pac NUMBER;
    v_act NUMBER;
  BEGIN
    FOR i IN 1 .. g_ids.COUNT LOOP
      SELECT id_paciente INTO v_pac
        FROM consulta WHERE id_consulta = g_ids(i);
      SELECT COUNT(*) INTO v_act
        FROM prescricao p
        JOIN consulta c ON c.id_consulta = p.id_consulta
       WHERE c.id_paciente = v_pac
         AND p.data_fim IS NULL;
      IF v_act > 1 THEN
        RAISE_APPLICATION_ERROR(-20003,
          'RN12: o paciente ja tem uma prescricao activa.');
      END IF;
    END LOOP;
    g_ids.DELETE;
  END AFTER STATEMENT;
END trg_prescricao_unica_activa;
/

-- RN15: nao ha dispensa sobre prescricao encerrada
CREATE OR REPLACE TRIGGER trg_dispensa_presc_activa
BEFORE INSERT ON dispensa
FOR EACH ROW
DECLARE
  v_fim prescricao.data_fim%TYPE;
BEGIN
  SELECT data_fim INTO v_fim
    FROM prescricao WHERE id_prescricao = :NEW.id_prescricao;
  IF v_fim IS NOT NULL AND v_fim < :NEW.data_dispensa THEN
    RAISE_APPLICATION_ERROR(-20004,
      'RN15: a prescricao ja foi encerrada em ' ||
      TO_CHAR(v_fim, 'DD/MM/YYYY') || '.');
  END IF;
END trg_dispensa_presc_activa;
/

-- RN04 / RN17: o resultado da busca activa actualiza o estado do paciente
CREATE OR REPLACE TRIGGER trg_busca_actualiza_estado
AFTER INSERT ON busca_activa
FOR EACH ROW
BEGIN
  IF :NEW.resultado IN ('TRANSFERIDO', 'OBITO') THEN
    UPDATE paciente SET estado_paciente = :NEW.resultado
     WHERE id_paciente = :NEW.id_paciente;
  ELSIF :NEW.resultado = 'REGRESSOU' THEN
    UPDATE paciente SET estado_paciente = 'ACTIVO'
     WHERE id_paciente = :NEW.id_paciente;
  END IF;
END trg_busca_actualiza_estado;
/

-- RN19: eliminacao fisica proibida nas tabelas clinicas (um trigger por
-- tabela, criado dinamicamente)
BEGIN
  FOR t IN (SELECT column_value AS nome
              FROM TABLE(sys.odcivarchar2list('PACIENTE','TESTE_HIV','CONSULTA',
                   'EXAME_LABORATORIAL','PRESCRICAO','DISPENSA','BUSCA_ACTIVA')))
  LOOP
    EXECUTE IMMEDIATE
      'CREATE OR REPLACE TRIGGER trg_bd_' || t.nome ||
      ' BEFORE DELETE ON ' || t.nome ||
      ' BEGIN RAISE_APPLICATION_ERROR(-20005, ' ||
      '''RN19: eliminacao fisica nao permitida em ' || t.nome || '''); END;';
  END LOOP;
END;
/


-- #####################################################################
-- PARTE 5 - 05_plsql.sql  (executar como HIV_MACHAVA)
-- Funcao, vistas e procedures. Mensagens sem acentos (compatibilidade).
-- #####################################################################

-- RN10: situacao da carga viral (limiar de 1000 copias/mL)
CREATE OR REPLACE FUNCTION fn_supressao_viral (p_valor IN NUMBER)
RETURN VARCHAR2 DETERMINISTIC
IS
BEGIN
  IF p_valor IS NULL THEN
    RETURN NULL;
  ELSIF p_valor < 1000 THEN
    RETURN 'SUPRIMIDA';
  ELSE
    RETURN 'NAO_SUPRIMIDA';
  END IF;
END fn_supressao_viral;
/

-- RN16: pacientes activos com levantamento em atraso
CREATE OR REPLACE VIEW vw_faltosos AS
SELECT p.id_paciente, p.nid, p.nome_completo, p.contacto_telefonico,
       MAX(d.data_proximo_levantamento)                    AS data_prevista,
       TRUNC(SYSDATE) - MAX(d.data_proximo_levantamento)   AS dias_atraso
  FROM paciente p
  JOIN consulta c   ON c.id_paciente   = p.id_paciente
  JOIN prescricao pr ON pr.id_consulta = c.id_consulta
  JOIN dispensa d   ON d.id_prescricao = pr.id_prescricao
 WHERE p.estado_paciente = 'ACTIVO'
 GROUP BY p.id_paciente, p.nid, p.nome_completo, p.contacto_telefonico
HAVING MAX(d.data_proximo_levantamento) < TRUNC(SYSDATE);

-- RN10: ultima carga viral de cada paciente e respectiva situacao
CREATE OR REPLACE VIEW vw_ultima_carga_viral AS
SELECT id_paciente, data_colheita, valor_resultado,
       fn_supressao_viral(valor_resultado) AS situacao
  FROM (SELECT e.id_paciente, e.data_colheita, e.valor_resultado,
               ROW_NUMBER() OVER (PARTITION BY e.id_paciente
                                  ORDER BY e.data_colheita DESC) AS rn
          FROM exame_laboratorial e
          JOIN tipo_exame t ON t.id_tipo_exame = e.id_tipo_exame
         WHERE t.designacao = 'Carga Viral')
 WHERE rn = 1;

-- RN01, RN03, RN20: registo de paciente
CREATE OR REPLACE PROCEDURE prc_registar_paciente (
  p_nid       IN VARCHAR2,
  p_nome      IN VARCHAR2,
  p_data_nasc IN DATE,
  p_sexo      IN CHAR,
  p_contacto  IN VARCHAR2,
  p_bairro    IN VARCHAR2,
  p_endereco  IN VARCHAR2,
  p_id        OUT NUMBER)
IS
BEGIN
  INSERT INTO paciente (nid, nome_completo, data_nascimento, sexo,
                        contacto_telefonico, bairro, endereco)
  VALUES (p_nid, p_nome, p_data_nasc, p_sexo, p_contacto, p_bairro, p_endereco)
  RETURNING id_paciente INTO p_id;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20010, 'RN01: NID ja existente: ' || p_nid);
END prc_registar_paciente;
/

-- RN05, RN06: registo de teste de HIV
CREATE OR REPLACE PROCEDURE prc_registar_teste (
  p_id_paciente IN NUMBER,
  p_id_prof     IN NUMBER,
  p_data        IN DATE,
  p_tipo        IN VARCHAR2,
  p_resultado   IN VARCHAR2,
  p_id          OUT NUMBER)
IS
BEGIN
  INSERT INTO teste_hiv (id_paciente, id_profissional, data_teste,
                         tipo_teste, resultado)
  VALUES (p_id_paciente, p_id_prof, p_data, p_tipo, p_resultado)
  RETURNING id_teste INTO p_id;
END prc_registar_teste;
/

-- RN12, RN13: prescricao; encerra a prescricao activa anterior
CREATE OR REPLACE PROCEDURE prc_prescrever_regime (
  p_id_consulta IN NUMBER,
  p_id_regime   IN NUMBER,
  p_data_inicio IN DATE,
  p_motivo      IN VARCHAR2 DEFAULT 'INICIO',
  p_id          OUT NUMBER)
IS
  v_pac NUMBER;
  v_act NUMBER;
BEGIN
  SELECT id_paciente INTO v_pac
    FROM consulta WHERE id_consulta = p_id_consulta;

  SELECT COUNT(*) INTO v_act
    FROM prescricao p
    JOIN consulta c ON c.id_consulta = p.id_consulta
   WHERE c.id_paciente = v_pac AND p.data_fim IS NULL;

  IF v_act > 0 AND p_motivo = 'INICIO' THEN
    RAISE_APPLICATION_ERROR(-20012,
      'RN13: a mudanca de regime exige um motivo diferente de INICIO.');
  END IF;

  UPDATE prescricao
     SET data_fim = p_data_inicio
   WHERE data_fim IS NULL
     AND id_consulta IN (SELECT id_consulta FROM consulta
                          WHERE id_paciente = v_pac);

  INSERT INTO prescricao (id_consulta, id_regime, data_inicio, motivo)
  VALUES (p_id_consulta, p_id_regime, p_data_inicio, p_motivo)
  RETURNING id_prescricao INTO p_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Consulta inexistente.');
END prc_prescrever_regime;
/

-- RN06, RN14: dispensa (so profissional de farmacia)
CREATE OR REPLACE PROCEDURE prc_registar_dispensa (
  p_id_prescricao IN NUMBER,
  p_id_prof       IN NUMBER,
  p_data          IN DATE,
  p_dias          IN NUMBER,
  p_id            OUT NUMBER)
IS
  v_cat profissional_saude.categoria%TYPE;
BEGIN
  SELECT categoria INTO v_cat
    FROM profissional_saude WHERE id_profissional = p_id_prof;

  IF v_cat <> 'FARMACEUTICO' THEN
    RAISE_APPLICATION_ERROR(-20013,
      'RN14: a dispensa so pode ser feita por profissional de farmacia.');
  END IF;

  INSERT INTO dispensa (id_prescricao, id_profissional, data_dispensa,
                        quantidade_dias, data_proximo_levantamento)
  VALUES (p_id_prescricao, p_id_prof, p_data, p_dias, p_data + p_dias)
  RETURNING id_dispensa INTO p_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20014, 'Profissional inexistente.');
END prc_registar_dispensa;
/

-- RN17: registo de busca activa
CREATE OR REPLACE PROCEDURE prc_registar_busca (
  p_id_paciente   IN NUMBER,
  p_data_falta    IN DATE,
  p_data_contacto IN DATE,
  p_meio          IN VARCHAR2,
  p_agente        IN VARCHAR2,
  p_resultado     IN VARCHAR2)
IS
BEGIN
  INSERT INTO busca_activa (id_paciente, data_falta, data_contacto,
                            meio_contacto, agente_responsavel, resultado)
  VALUES (p_id_paciente, p_data_falta, p_data_contacto,
          p_meio, p_agente, p_resultado);
END prc_registar_busca;
/

-- RN04, RN16: passa a ABANDONO os faltosos com atraso superior ao limite
CREATE OR REPLACE PROCEDURE prc_actualizar_abandonos (
  p_limite_dias IN NUMBER DEFAULT 90,
  p_total       OUT NUMBER)
IS
BEGIN
  UPDATE paciente
     SET estado_paciente = 'ABANDONO'
   WHERE id_paciente IN (SELECT id_paciente FROM vw_faltosos
                          WHERE dias_atraso > p_limite_dias);
  p_total := SQL%ROWCOUNT;
END prc_actualizar_abandonos;
/


-- #####################################################################
-- PARTE 6 - 06_perfis_acesso.sql  (executar como HIV_MACHAVA)
-- Privilegios minimos por perfil. RN18, RNF01
-- Os papeis foram criados na PARTE 1.
-- #####################################################################

-- Vista com dados minimos do paciente (sem contactos nem morada)
CREATE OR REPLACE VIEW vw_paciente_basico AS
SELECT id_paciente, nid, nome_completo, sexo, data_nascimento, estado_paciente
  FROM paciente;

-- Medico / enfermeiro
GRANT SELECT, INSERT, UPDATE ON paciente           TO rl_medico;
GRANT SELECT, INSERT, UPDATE ON teste_hiv          TO rl_medico;
GRANT SELECT, INSERT, UPDATE ON consulta           TO rl_medico;
GRANT SELECT, INSERT, UPDATE ON prescricao         TO rl_medico;
GRANT SELECT ON exame_laboratorial                 TO rl_medico;
GRANT SELECT ON tipo_exame                         TO rl_medico;
GRANT SELECT ON regime_tarv                        TO rl_medico;
GRANT SELECT ON medicamento                        TO rl_medico;
GRANT SELECT ON composicao_regime                  TO rl_medico;
GRANT SELECT ON dispensa                           TO rl_medico;
GRANT SELECT ON busca_activa                       TO rl_medico;
GRANT SELECT ON vw_faltosos                        TO rl_medico;
GRANT SELECT ON vw_ultima_carga_viral              TO rl_medico;
GRANT EXECUTE ON prc_registar_paciente             TO rl_medico;
GRANT EXECUTE ON prc_registar_teste                TO rl_medico;
GRANT EXECUTE ON prc_prescrever_regime             TO rl_medico;

-- Tecnico de laboratorio
GRANT SELECT ON vw_paciente_basico                 TO rl_laboratorio;
GRANT SELECT ON tipo_exame                         TO rl_laboratorio;
GRANT SELECT, INSERT, UPDATE ON exame_laboratorial TO rl_laboratorio;

-- Farmacia
GRANT SELECT ON vw_paciente_basico                 TO rl_farmacia;
GRANT SELECT ON prescricao                         TO rl_farmacia;
GRANT SELECT ON regime_tarv                        TO rl_farmacia;
GRANT SELECT ON medicamento                        TO rl_farmacia;
GRANT SELECT ON composicao_regime                  TO rl_farmacia;
GRANT SELECT ON dispensa                           TO rl_farmacia;
GRANT SELECT ON vw_faltosos                        TO rl_farmacia;
GRANT EXECUTE ON prc_registar_dispensa             TO rl_farmacia;

-- Administrador do servico
GRANT SELECT, INSERT, UPDATE ON profissional_saude TO rl_administrador;
GRANT SELECT, INSERT, UPDATE ON tipo_exame         TO rl_administrador;
GRANT SELECT, INSERT, UPDATE ON regime_tarv        TO rl_administrador;
GRANT SELECT, INSERT, UPDATE ON medicamento        TO rl_administrador;
GRANT SELECT, INSERT, UPDATE ON composicao_regime  TO rl_administrador;
GRANT SELECT ON paciente                           TO rl_administrador;
GRANT SELECT ON busca_activa                       TO rl_administrador;
GRANT SELECT ON vw_faltosos                        TO rl_administrador;
GRANT EXECUTE ON prc_registar_busca                TO rl_administrador;
GRANT EXECUTE ON prc_actualizar_abandonos          TO rl_administrador;

-- Exemplo de utilizadores (executar como SYSTEM):
-- CREATE USER u_farmacia IDENTIFIED BY "Alterar#2026";
-- GRANT rl_farmacia TO u_farmacia;


-- #####################################################################
-- PARTE 7 - 07_dados_teste.sql  (executar como HIV_MACHAVA, apos partes 1 a 6)
-- Dados FICTICIOS e ilustrativos, sem valor clinico.
-- As datas sao relativas a data actual, para que faltosos e abandonos
-- sejam reproduziveis em qualquer dia de execucao.
-- #####################################################################
SET SERVEROUTPUT ON

-- ------------------------ catalogos ---------------------------------
INSERT INTO tipo_exame (designacao, unidade_medida) VALUES ('CD4', 'celulas/mm3');
INSERT INTO tipo_exame (designacao, unidade_medida) VALUES ('Carga Viral', 'copias/ml');
INSERT INTO tipo_exame (designacao, unidade_medida) VALUES ('Hemoglobina', 'g/dl');

INSERT INTO medicamento (nome_generico, dosagem, forma_farmaceutica)
  VALUES ('Tenofovir (TDF)', '300 mg', 'Comprimido');
INSERT INTO medicamento (nome_generico, dosagem, forma_farmaceutica)
  VALUES ('Lamivudina (3TC)', '300 mg', 'Comprimido');
INSERT INTO medicamento (nome_generico, dosagem, forma_farmaceutica)
  VALUES ('Dolutegravir (DTG)', '50 mg', 'Comprimido');
INSERT INTO medicamento (nome_generico, dosagem, forma_farmaceutica)
  VALUES ('Zidovudina (AZT)', '300 mg', 'Comprimido');
INSERT INTO medicamento (nome_generico, dosagem, forma_farmaceutica)
  VALUES ('Lopinavir/ritonavir (LPV/r)', '200/50 mg', 'Comprimido');

INSERT INTO regime_tarv (codigo, descricao, linha_tratamento)
  VALUES ('TDF+3TC+DTG', 'Tenofovir + Lamivudina + Dolutegravir', 1);
INSERT INTO regime_tarv (codigo, descricao, linha_tratamento)
  VALUES ('AZT+3TC+LPV/r', 'Zidovudina + Lamivudina + Lopinavir/ritonavir', 2);

INSERT INTO composicao_regime (id_regime, id_medicamento, posologia)
SELECT r.id_regime, m.id_medicamento, c.posologia
  FROM (SELECT 'TDF+3TC+DTG' reg, 'Tenofovir (TDF)' med,
               '1 comprimido ao deitar' posologia FROM dual
        UNION ALL SELECT 'TDF+3TC+DTG', 'Lamivudina (3TC)',
               '1 comprimido ao deitar' FROM dual
        UNION ALL SELECT 'TDF+3TC+DTG', 'Dolutegravir (DTG)',
               '1 comprimido ao deitar' FROM dual
        UNION ALL SELECT 'AZT+3TC+LPV/r', 'Zidovudina (AZT)',
               '1 comprimido de 12 em 12 h' FROM dual
        UNION ALL SELECT 'AZT+3TC+LPV/r', 'Lamivudina (3TC)',
               '1 comprimido de 12 em 12 h' FROM dual
        UNION ALL SELECT 'AZT+3TC+LPV/r', 'Lopinavir/ritonavir (LPV/r)',
               '2 comprimidos de 12 em 12 h' FROM dual) c
  JOIN regime_tarv r ON r.codigo = c.reg
  JOIN medicamento m ON m.nome_generico = c.med;

-- ---------------- profissionais, pacientes e movimentos --------------
DECLARE
  v_hoje DATE := TRUNC(SYSDATE);
  v_med NUMBER; v_enf NUMBER; v_lab NUMBER; v_far NUMBER; v_con NUMBER;
  v_p1 NUMBER; v_p2 NUMBER; v_p3 NUMBER; v_p4 NUMBER; v_p5 NUMBER; v_p6 NUMBER;
  v_r1 NUMBER; v_r2 NUMBER; v_cd4 NUMBER; v_cv NUMBER;
  v_id NUMBER; v_c NUMBER; v_pr NUMBER;

  PROCEDURE prof (p_nome VARCHAR2, p_cat VARCHAR2, p_reg VARCHAR2, o_id OUT NUMBER) IS
  BEGIN
    INSERT INTO profissional_saude (nome_completo, categoria, num_registo, contacto)
    VALUES (p_nome, p_cat, p_reg, '84 000 0000')
    RETURNING id_profissional INTO o_id;
  END;

  PROCEDURE teste (p_pac NUMBER, p_data DATE, p_tipo VARCHAR2, p_res VARCHAR2) IS
    v NUMBER;
  BEGIN
    prc_registar_teste(p_pac, v_con, p_data, p_tipo, p_res, v);
  END;

  PROCEDURE cons (p_pac NUMBER, p_data DATE, p_tipo VARCHAR2, p_peso NUMBER,
                  p_est NUMBER, p_prox DATE, o_id OUT NUMBER) IS
  BEGIN
    INSERT INTO consulta (id_paciente, id_profissional, data_consulta,
                          tipo_consulta, peso_kg, estadio_oms, data_proxima_consulta)
    VALUES (p_pac, v_med, p_data, p_tipo, p_peso, p_est, p_prox)
    RETURNING id_consulta INTO o_id;
  END;

  PROCEDURE exame (p_pac NUMBER, p_tipo NUMBER, p_cons NUMBER, p_data DATE,
                   p_valor NUMBER) IS
  BEGIN
    INSERT INTO exame_laboratorial (id_paciente, id_tipo_exame, id_consulta,
                                    id_profissional, data_colheita,
                                    data_resultado, valor_resultado)
    VALUES (p_pac, p_tipo, p_cons, v_lab, p_data, p_data + 2, p_valor);
  END;
BEGIN
  prof('Amelia Cossa',      'MEDICO',             'MED-0001', v_med);
  prof('Bernardo Mabjaia',  'ENFERMEIRO',         'ENF-0002', v_enf);
  prof('Carla Sitoe',       'TECNICO_LABORATORIO','LAB-0003', v_lab);
  prof('Domingos Chongo',   'FARMACEUTICO',       'FAR-0004', v_far);
  prof('Esperanca Tembe',   'CONSELHEIRO',        'CON-0005', v_con);

  SELECT id_tipo_exame INTO v_cd4 FROM tipo_exame WHERE designacao = 'CD4';
  SELECT id_tipo_exame INTO v_cv  FROM tipo_exame WHERE designacao = 'Carga Viral';
  SELECT id_regime INTO v_r1 FROM regime_tarv WHERE codigo = 'TDF+3TC+DTG';
  SELECT id_regime INTO v_r2 FROM regime_tarv WHERE codigo = 'AZT+3TC+LPV/r';

  prc_registar_paciente('NID-0001', 'Ana Maria Macie', DATE '1985-03-12', 'F',
                        '84 000 0001', 'Machava Sede', 'Casa 12', v_p1);
  prc_registar_paciente('NID-0002', 'Joao Pedro Nhaca', DATE '1979-07-30', 'M',
                        '84 000 0002', 'Machava Socimol', 'Casa 7', v_p2);
  prc_registar_paciente('NID-0003', 'Luisa Fernando Bila', DATE '1992-11-05', 'F',
                        '84 000 0003', 'Machava Sede', 'Casa 31', v_p3);
  prc_registar_paciente('NID-0004', 'Carlos Alberto Uamusse', DATE '1988-01-20', 'M',
                        '84 000 0004', 'Machava Socimol', 'Casa 4', v_p4);
  prc_registar_paciente('NID-0005', 'Marta Isabel Nhantumbo', DATE '2001-06-18', 'F',
                        '84 000 0005', 'Machava Sede', 'Casa 22', v_p5);
  prc_registar_paciente('NID-0006', 'Rui Manuel Timana', DATE '1995-09-09', 'M',
                        '84 000 0006', 'Machava Sede', 'Casa 9', v_p6);

  -- Paciente 1: boa resposta ao tratamento (carga viral suprimida)
  teste(v_p1, v_hoje - 260, 'DIAGNOSTICO', 'REACTIVO');
  cons(v_p1, v_hoje - 258, 'INICIAL', 62, 2, v_hoje - 228, v_c);
  exame(v_p1, v_cd4, v_c, v_hoje - 258, 310);
  exame(v_p1, v_cv,  v_c, v_hoje - 258, 45000);
  prc_prescrever_regime(v_c, v_r1, v_hoje - 258, 'INICIO', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 258, 30, v_id);
  cons(v_p1, v_hoje - 60, 'SEGUIMENTO', 65, 1, v_hoje + 30, v_c);
  exame(v_p1, v_cv, v_c, v_hoje - 60, 200);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 20, 90, v_id);

  -- Paciente 2: falencia terapeutica e mudanca para 2.a linha
  teste(v_p2, v_hoje - 240, 'DIAGNOSTICO', 'REACTIVO');
  cons(v_p2, v_hoje - 238, 'INICIAL', 70, 3, v_hoje - 208, v_c);
  exame(v_p2, v_cd4, v_c, v_hoje - 238, 180);
  exame(v_p2, v_cv,  v_c, v_hoje - 238, 150000);
  prc_prescrever_regime(v_c, v_r1, v_hoje - 238, 'INICIO', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 238, 30, v_id);
  cons(v_p2, v_hoje - 100, 'SEGUIMENTO', 68, 3, v_hoje - 70, v_c);
  exame(v_p2, v_cv, v_c, v_hoje - 100, 5200);
  prc_prescrever_regime(v_c, v_r2, v_hoje - 100, 'FALENCIA_TERAPEUTICA', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 45, 30, v_id);  -- faltoso (15 dias)

  -- Paciente 3: inicio recente, sem atraso
  teste(v_p3, v_hoje - 30, 'DIAGNOSTICO', 'REACTIVO');
  cons(v_p3, v_hoje - 28, 'INICIAL', 58, 2, v_hoje + 32, v_c);
  exame(v_p3, v_cd4, v_c, v_hoje - 28, 420);
  prc_prescrever_regime(v_c, v_r1, v_hoje - 28, 'INICIO', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 28, 60, v_id);

  -- Paciente 4: abandono (120 dias de atraso) com busca activa
  teste(v_p4, v_hoje - 200, 'DIAGNOSTICO', 'REACTIVO');
  cons(v_p4, v_hoje - 198, 'INICIAL', 74, 2, v_hoje - 168, v_c);
  prc_prescrever_regime(v_c, v_r1, v_hoje - 198, 'INICIO', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 150, 30, v_id);
  prc_registar_busca(v_p4, v_hoje - 120, v_hoje - 115, 'TELEFONE',
                     'Esperanca Tembe', 'NAO_LOCALIZADO');

  -- Paciente 5: faltoso recente (10 dias de atraso)
  teste(v_p5, v_hoje - 60, 'DIAGNOSTICO', 'REACTIVO');
  cons(v_p5, v_hoje - 58, 'INICIAL', 55, 1, v_hoje - 28, v_c);
  prc_prescrever_regime(v_c, v_r1, v_hoje - 58, 'INICIO', v_pr);
  prc_registar_dispensa(v_pr, v_far, v_hoje - 40, 30, v_id);

  -- Paciente 6: teste NAO reactivo (nao pode ter consultas - RN02)
  teste(v_p6, v_hoje - 5, 'DIAGNOSTICO', 'NAO_REACTIVO');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Dados de teste inseridos com sucesso.');
END;
/


-- #####################################################################
-- PARTE 8 - 08_testes_integridade.sql  (executar como HIV_MACHAVA, apos parte 7)
-- Cada bloco tenta violar uma regra de negocio. O resultado esperado e
-- uma linha "OK" com a mensagem de erro. Tudo e desfeito com ROLLBACK.
-- #####################################################################
SET SERVEROUTPUT ON

-- I01 (RN01): NID duplicado
DECLARE v_id NUMBER;
BEGIN
  prc_registar_paciente('NID-0001', 'Duplicado', DATE '1990-01-01', 'F',
                        NULL, 'Machava Sede', NULL, v_id);
  DBMS_OUTPUT.PUT_LINE('I01 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I01 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I02 (RN20): data de nascimento futura
DECLARE v_id NUMBER;
BEGIN
  prc_registar_paciente('NID-0099', 'Futuro', SYSDATE + 1, 'M',
                        NULL, 'Machava Sede', NULL, v_id);
  DBMS_OUTPUT.PUT_LINE('I02 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I02 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I03 (RN02): consulta de paciente sem teste reactivo (NID-0006)
DECLARE v_pac NUMBER; v_prof NUMBER;
BEGIN
  SELECT id_paciente INTO v_pac FROM paciente WHERE nid = 'NID-0006';
  SELECT id_profissional INTO v_prof FROM profissional_saude WHERE num_registo = 'MED-0001';
  INSERT INTO consulta (id_paciente, id_profissional, data_consulta, tipo_consulta)
  VALUES (v_pac, v_prof, SYSDATE, 'INICIAL');
  DBMS_OUTPUT.PUT_LINE('I03 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I03 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I04 (RN08): proxima consulta anterior a consulta (CHECK)
DECLARE v_pac NUMBER; v_prof NUMBER;
BEGIN
  SELECT id_paciente INTO v_pac FROM paciente WHERE nid = 'NID-0001';
  SELECT id_profissional INTO v_prof FROM profissional_saude WHERE num_registo = 'MED-0001';
  INSERT INTO consulta (id_paciente, id_profissional, data_consulta,
                        tipo_consulta, data_proxima_consulta)
  VALUES (v_pac, v_prof, SYSDATE, 'SEGUIMENTO', SYSDATE - 10);
  DBMS_OUTPUT.PUT_LINE('I04 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I04 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I05 (RN12): segunda prescricao activa (insercao directa)
DECLARE v_cons NUMBER; v_reg NUMBER;
BEGIN
  SELECT c.id_consulta INTO v_cons
    FROM consulta c JOIN paciente p ON p.id_paciente = c.id_paciente
   WHERE p.nid = 'NID-0003' AND ROWNUM = 1;
  SELECT id_regime INTO v_reg FROM regime_tarv WHERE codigo = 'AZT+3TC+LPV/r';
  INSERT INTO prescricao (id_consulta, id_regime, data_inicio, motivo)
  VALUES (v_cons, v_reg, TRUNC(SYSDATE), 'OUTRO');
  DBMS_OUTPUT.PUT_LINE('I05 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I05 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I06 (RN13): mudanca de regime com motivo INICIO
DECLARE v_cons NUMBER; v_reg NUMBER; v_id NUMBER;
BEGIN
  SELECT c.id_consulta INTO v_cons
    FROM consulta c JOIN paciente p ON p.id_paciente = c.id_paciente
   WHERE p.nid = 'NID-0003' AND ROWNUM = 1;
  SELECT id_regime INTO v_reg FROM regime_tarv WHERE codigo = 'AZT+3TC+LPV/r';
  prc_prescrever_regime(v_cons, v_reg, TRUNC(SYSDATE), 'INICIO', v_id);
  DBMS_OUTPUT.PUT_LINE('I06 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I06 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I07 (RN14): dispensa feita por profissional que nao e de farmacia
DECLARE v_presc NUMBER; v_prof NUMBER; v_id NUMBER;
BEGIN
  SELECT pr.id_prescricao INTO v_presc
    FROM prescricao pr
    JOIN consulta c ON c.id_consulta = pr.id_consulta
    JOIN paciente p ON p.id_paciente = c.id_paciente
   WHERE p.nid = 'NID-0003' AND pr.data_fim IS NULL;
  SELECT id_profissional INTO v_prof FROM profissional_saude WHERE num_registo = 'ENF-0002';
  prc_registar_dispensa(v_presc, v_prof, TRUNC(SYSDATE), 30, v_id);
  DBMS_OUTPUT.PUT_LINE('I07 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I07 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I08 (RN15): dispensa sobre prescricao encerrada (paciente NID-0002)
DECLARE v_presc NUMBER; v_prof NUMBER; v_id NUMBER;
BEGIN
  SELECT pr.id_prescricao INTO v_presc
    FROM prescricao pr
    JOIN consulta c ON c.id_consulta = pr.id_consulta
    JOIN paciente p ON p.id_paciente = c.id_paciente
   WHERE p.nid = 'NID-0002' AND pr.data_fim IS NOT NULL;
  SELECT id_profissional INTO v_prof FROM profissional_saude WHERE num_registo = 'FAR-0004';
  prc_registar_dispensa(v_presc, v_prof, TRUNC(SYSDATE), 30, v_id);
  DBMS_OUTPUT.PUT_LINE('I08 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I08 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I09 (RN19): eliminacao fisica de dados clinicos
BEGIN
  DELETE FROM consulta WHERE ROWNUM = 1;
  DBMS_OUTPUT.PUT_LINE('I09 FALHOU: nao gerou erro');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('I09 OK -> ' || SQLERRM); ROLLBACK;
END;
/

-- I10 (RN16, RN04): abandono automatico (esperado: 1 paciente, NID-0004)
DECLARE v_total NUMBER; v_estado VARCHAR2(15);
BEGIN
  prc_actualizar_abandonos(90, v_total);
  SELECT estado_paciente INTO v_estado FROM paciente WHERE nid = 'NID-0004';
  DBMS_OUTPUT.PUT_LINE('I10 pacientes passados a ABANDONO: ' || v_total ||
                       ' | estado do NID-0004: ' || v_estado);
  ROLLBACK;
END;
/

-- I11 (RN10): situacao da ultima carga viral de cada paciente
SELECT p.nid, v.data_colheita, v.valor_resultado, v.situacao
  FROM vw_ultima_carga_viral v
  JOIN paciente p ON p.id_paciente = v.id_paciente
 ORDER BY p.nid;

-- I12 (RN16): faltosos actuais
SELECT nid, nome_completo, data_prevista, dias_atraso
  FROM vw_faltosos ORDER BY dias_atraso DESC;


-- #####################################################################
-- PARTE 9 - 09_contagens.sql  (executar como HIV_MACHAVA)
-- Contagem de registos por tabela. Usado antes e depois de cada teste de
-- backup/recovery para comprovar que nao houve perda de dados.
-- Esperado: PACIENTE 6, PROFISSIONAL_SAUDE 5, TESTE_HIV 6, CONSULTA 7,
--           TIPO_EXAME 3, EXAME_LABORATORIAL 7, REGIME_TARV 2, MEDICAMENTO 5,
--           COMPOSICAO_REGIME 6, PRESCRICAO 6, DISPENSA 7, BUSCA_ACTIVA 1
-- #####################################################################
SELECT 'PACIENTE' AS tabela, COUNT(*) AS total FROM paciente
UNION ALL SELECT 'PROFISSIONAL_SAUDE', COUNT(*) FROM profissional_saude
UNION ALL SELECT 'TESTE_HIV',          COUNT(*) FROM teste_hiv
UNION ALL SELECT 'CONSULTA',           COUNT(*) FROM consulta
UNION ALL SELECT 'TIPO_EXAME',         COUNT(*) FROM tipo_exame
UNION ALL SELECT 'EXAME_LABORATORIAL', COUNT(*) FROM exame_laboratorial
UNION ALL SELECT 'REGIME_TARV',        COUNT(*) FROM regime_tarv
UNION ALL SELECT 'MEDICAMENTO',        COUNT(*) FROM medicamento
UNION ALL SELECT 'COMPOSICAO_REGIME',  COUNT(*) FROM composicao_regime
UNION ALL SELECT 'PRESCRICAO',         COUNT(*) FROM prescricao
UNION ALL SELECT 'DISPENSA',           COUNT(*) FROM dispensa
UNION ALL SELECT 'BUSCA_ACTIVA',       COUNT(*) FROM busca_activa;


-- #####################################################################
-- PARTE 10 - EVIDENCIAS (fase 5.7.10)  (executar como HIV_MACHAVA)
-- Tirar capturas de ecra de cada resultado.
-- #####################################################################

-- Figura 6: tabelas e restricoes
-- Esperado: 12 tabelas; P = 12, R = 15, U = 5 (C = NOT NULL e CHECK)
SELECT table_name FROM user_tables ORDER BY 1;
SELECT constraint_type, COUNT(*) AS total
  FROM user_constraints GROUP BY constraint_type ORDER BY 1;

-- Figura 7: indices, sequencias, triggers, procedures e vistas
-- Esperado: FUNCTION 1, PROCEDURE 6, SEQUENCE 11, TRIGGER 12, VIEW 3 (todos VALID)
SELECT index_name, table_name FROM user_indexes ORDER BY 2, 1;
SELECT object_type, object_name, status FROM user_objects
 WHERE object_type IN ('SEQUENCE','TRIGGER','PROCEDURE','FUNCTION','VIEW')
 ORDER BY 1, 2;
SELECT object_type, COUNT(*) AS total,
       SUM(CASE WHEN status = 'VALID' THEN 1 ELSE 0 END) AS validos
  FROM user_objects
 WHERE object_type IN ('SEQUENCE','TRIGGER','PROCEDURE','FUNCTION','VIEW')
 GROUP BY object_type ORDER BY 1;
 
-- Privilégios de sistema do utilizador
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = 'NOME_UTILIZADOR';

-- Roles atribuídas
SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE = 'NOME_UTILIZADOR';

-- Privilégios sobre objectos (tabelas, etc.)
SELECT * FROM DBA_TAB_PRIVS WHERE GRANTEE = 'NOME_UTILIZADOR';
