#!/bin/bash

# Create project directory structure
mkdir -p liquibase-oracle-test/{liquibase,drivers,init-scripts,scripts}

cd liquibase-oracle-test

# Create the main changelog file
cat > liquibase/db.changelog-master.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                   http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.0.xsd">

    <!-- Include other changelog files -->
    <include file="001-create-test-mview.xml" relativeToChangelogFile="true"/>
    <include file="002-refresh-mview.xml" relativeToChangelogFile="true"/>
    
</databaseChangeLog>
EOF

# Create test materialized view
cat > liquibase/001-create-test-mview.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                   http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.0.xsd">

    <changeSet id="create-test-table" author="test">
        <sql>
            CREATE TABLE test_data (
                id NUMBER PRIMARY KEY,
                name VARCHAR2(100),
                created_date DATE DEFAULT SYSDATE
            )
        </sql>
    </changeSet>

    <changeSet id="insert-test-data" author="test">
        <sql>
            INSERT INTO test_data (id, name) VALUES (1, 'Test Record 1');
            INSERT INTO test_data (id, name) VALUES (2, 'Test Record 2');
            INSERT INTO test_data (id, name) VALUES (3, 'Test Record 3');
            COMMIT;
        </sql>
    </changeSet>

    <changeSet id="create-materialized-view" author="test">
        <sql>
            CREATE MATERIALIZED VIEW test_mview
            BUILD IMMEDIATE
            REFRESH COMPLETE ON DEMAND
            AS SELECT id, name, created_date FROM test_data
        </sql>
    </changeSet>

</databaseChangeLog>
EOF

# Create refresh changeset
cat > liquibase/002-refresh-mview.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                   http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.0.xsd">

    <changeSet id="refresh-materialized-view" author="test">
        <sql splitStatements="false">
            BEGIN
                DBMS_MVIEW.REFRESH('TEST_MVIEW', 'C');
            END;
            /
        </sql>
    </changeSet>

    <changeSet id="refresh-with-error-handling" author="test">
        <sql splitStatements="false">
            DECLARE
                v_count NUMBER;
            BEGIN
                -- Add more test data
                INSERT INTO test_data (id, name) VALUES (4, 'New Record After Refresh');
                COMMIT;
                
                -- Refresh the materialized view
                DBMS_MVIEW.REFRESH('TEST_MVIEW', 'C');
                
                -- Verify the refresh worked
                SELECT COUNT(*) INTO v_count FROM test_mview;
                DBMS_OUTPUT.PUT_LINE('Materialized view now contains ' || v_count || ' records');
                
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error refreshing materialized view: ' || SQLERRM);
                    RAISE;
            END;
            /
        </sql>
    </changeSet>

</databaseChangeLog>
EOF

# Create liquibase properties file
cat > liquibase/liquibase.properties << 'EOF'
driver=oracle.jdbc.OracleDriver
classpath=/liquibase/lib/ojdbc11.jar
url=jdbc:oracle:thin:@oracle-db:1521:XE
username=system
password=Oracle123!
changeLogFile=/liquibase/changelog/db.changelog-master.xml
logLevel=INFO
EOF

# Create helper scripts
cat > scripts/run-liquibase.sh << 'EOF'
#!/bin/bash

# Function to run liquibase commands
run_liquibase() {
    docker-compose exec liquibase liquibase "$@"
}

case "$1" in
    "update")
        echo "Running Liquibase update..."
        run_liquibase update
        ;;
    "status")
        echo "Checking Liquibase status..."
        run_liquibase status
        ;;
    "rollback")
        if [ -z "$2" ]; then
            echo "Usage: $0 rollback <tag>"
            exit 1
        fi
        echo "Rolling back to tag: $2"
        run_liquibase rollback "$2"
        ;;
    "validate")
        echo "Validating changelog..."
        run_liquibase validate
        ;;
    "history")
        echo "Showing deployment history..."
        run_liquibase history
        ;;
    *)
        echo "Usage: $0 {update|status|rollback|validate|history}"
        echo "Available commands:"
        echo "  update   - Apply pending changesets"
        echo "  status   - Show pending changesets"
        echo "  rollback - Rollback to specified tag"
        echo "  validate - Validate changelog"
        echo "  history  - Show deployment history"
        exit 1
        ;;
esac
EOF

chmod +x scripts/run-liquibase.sh

# Create SQL test script
cat > scripts/test-oracle.sh << 'EOF'
#!/bin/bash

echo "Testing Oracle connection and querying materialized view..."

docker-compose exec oracle-db sqlplus -s system/Oracle123!@//localhost:1521/XE << 'SQL'
SET PAGESIZE 100
SET LINESIZE 200

SELECT 'Current time: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') FROM DUAL;

SELECT 'Materialized View Contents:' FROM DUAL;
SELECT * FROM test_mview ORDER BY id;

SELECT 'Base Table Contents:' FROM DUAL;
SELECT * FROM test_data ORDER BY id;

EXIT;
SQL
EOF

chmod +x scripts/test-oracle.sh

echo "Project structure created successfully!"
echo ""
echo "Directory structure:"
find . -type f | sort