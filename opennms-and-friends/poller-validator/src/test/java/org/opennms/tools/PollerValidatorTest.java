package org.opennms.tools;

import java.io.File;
import java.io.FileWriter;
import java.util.Properties;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class PollerValidatorTest {

    // FIXME This must be updated with the real home directory. It should contain at least the whole etc directory.
    public static final String ONMS_HOME = "/Users/agalue/Development/opennms/customers/Bonnier/config/web01";

    private PollerValidator validator;

    @Before
    public void setUp() throws Exception {
        System.setProperty("user.dir",  ONMS_HOME);
        System.setProperty("opennms.home",  ONMS_HOME);
        validator = new PollerValidator();
        validator.initialize();
    }

    @Test
    public void testSanityCheck() throws Exception {
        validator.sanityCheck();
    }

    @Test
    public void testDatabsaeCheck() throws Exception {
        validator.databaseCheck();
    }

    @Test
    public void testOrganizeMonitors() throws Exception {
        validator.organizeMonitors();
    }

    @Test
    public void testDisplayReport() throws Exception {
        Properties p = validator.displayReport();
        p.store(new FileWriter(new File("target/current-services.properties")), "Created by Alejandro Galue");
        Assert.assertFalse(p.isEmpty());
    }

    @Test
    public void testForcedUnmanaged() throws Exception {
        validator.testForcedUnmanaged();
    }

}
