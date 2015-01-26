package org.opennms.tools;

import java.io.File;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

import org.apache.commons.lang.StringUtils;

import org.opennms.core.utils.ThreadCategory;
import org.opennms.core.utils.ThreadCategory.Level;

import org.opennms.netmgt.config.poller.Monitor;
import org.opennms.netmgt.config.poller.Package;
import org.opennms.netmgt.config.poller.Parameter;
import org.opennms.netmgt.config.poller.Service;
import org.opennms.netmgt.config.PollerConfig;
import org.opennms.netmgt.config.PollerConfigFactory;
import org.opennms.netmgt.config.PollerConfigManager;
import org.opennms.netmgt.dao.MonitoredServiceDao;
import org.opennms.netmgt.model.OnmsMonitoredService;
import org.opennms.netmgt.model.OnmsNode;
import org.opennms.netmgt.model.PollStatus;
import org.opennms.netmgt.poller.ServiceMonitor;

import org.springframework.beans.factory.BeanFactory;
import org.springframework.beans.factory.access.BeanFactoryReference;
import org.springframework.context.access.DefaultLocatorFactory;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionCallback;
import org.springframework.transaction.support.TransactionTemplate;

public class PollerValidator {

    private PollerConfig pollerConfig;
    private TransactionTemplate transactionTemplate;
    private MonitoredServiceDao monitoredServiceDao;

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.err.println("Please specify a valid OpenNMS Home directory.");
            System.exit(0);
        }
        File homeDir = new File(args[0]);
        if (!homeDir.exists() || !homeDir.isDirectory()) {
            System.err.println("Please specify a valid OpenNMS Home directory.");
            System.exit(0);

        }
        System.setProperty("opennms.home",  homeDir.getAbsolutePath());
        System.setProperty("user.dir",  homeDir.getAbsolutePath());
        PollerValidator v = new PollerValidator();
        v.initialize();
        v.sanityCheck();
        v.databaseCheck();
    }

    public void initialize() throws Exception {
        ThreadCategory.getInstance().setLevel(Level.WARN);
        System.setProperty("org.opennms.rrd.strategyClass", "org.opennms.netmgt.rrd.jrobin.JRobinRrdStrategy");
        System.setProperty("rrd.base.dir", "/tmp");
        System.setProperty("rrd.binary", "/usr/bin/rrdtool");

        BeanFactoryReference bfr = DefaultLocatorFactory.getInstance().useBeanFactory("daoContext");
        BeanFactory bf = bfr.getFactory();
        monitoredServiceDao = bf.getBean(MonitoredServiceDao.class);
        transactionTemplate = bf.getBean(TransactionTemplate.class);

        PollerConfigFactory.init();
        pollerConfig = PollerConfigFactory.getInstance();
        pollerConfig.rebuildPackageIpListMap();
    }

    public void sanityCheck() throws Exception {
        Map<String,Integer> monitorsTracker = new TreeMap<String,Integer>();
        Map<String,Integer> packagesTracker = new TreeMap<String,Integer>();
        Map<String,Set<String>> activeServicesTracker = new TreeMap<String,Set<String>>();
        Map<String,Set<String>> inactiveServicesTracker = new TreeMap<String,Set<String>>();

        for (Package p : ((PollerConfigManager) pollerConfig).packages()) {
            // Track package definitions
            int count = packagesTracker.containsKey(p.getName()) ? packagesTracker.get(p.getName()) : 0;
            packagesTracker.put(p.getName(), count + 1);
            // Track active/inactive services definitions
            for (Service s : p.getServiceCollection()) {
                if (!activeServicesTracker.containsKey(s.getName())) {
                    activeServicesTracker.put(s.getName(), new TreeSet<String>());
                }
                if (s.getStatus().equals("on")) {
                    activeServicesTracker.get(s.getName()).add(p.getName());
                } else {
                    if (!inactiveServicesTracker.containsKey(s.getName())) {
                        inactiveServicesTracker.put(s.getName(), new TreeSet<String>());
                    }
                    inactiveServicesTracker.get(s.getName()).add(p.getName());
                }
            }
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display duplicated packages (different packages with the same name)");
        System.out.println("-------------------------------------------------------------------------------");
        int found = 0;
        for (Entry<String,Integer> entry : packagesTracker.entrySet()) {
            if (entry.getValue() > 1) {
                found++;
                System.out.println("ERROR: The package's name " + entry.getKey() + " is being used on " + entry.getValue() + " packages");
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display invalid monitors (ClassNotFound exception)");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        for (Monitor m : ((PollerConfigManager) pollerConfig).monitors()) {
            // Track monitors definitions
            int count = monitorsTracker.containsKey(m.getService()) ? monitorsTracker.get(m.getService()) : 0;
            monitorsTracker.put(m.getService(), count + 1);
            if (pollerConfig.getServiceMonitor(m.getService()) == null) {
                found++;
                System.out.println("ERROR: The monitor for service " + m.getService() + " is invalid (should be removed): " + m.getClassName());
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display configured monitors entries that are not used");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        // TODO: Find a way to check typo errors on service definitions (like HTTP/http)
        for (Monitor m : ((PollerConfigManager) pollerConfig).monitors()) {
            if (!activeServicesTracker.containsKey(m.getService())) {
                found++;
                System.out.println("WARN: The monitor for service " + m.getService() + " has no references on any package");
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display duplicated monitors entries");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        for (Entry<String,Integer> entry : monitorsTracker.entrySet()) {
            if (entry.getValue() > 1) {
                found++;
                System.out.println("WARN: The monitor for service " + entry.getKey() + " is defined " + entry.getValue() + " times");
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display duplicated services on several packages");
        System.out.println("Maybe this is intended, for example when overriding services");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        for (Entry<String,Set<String>> entry : activeServicesTracker.entrySet()) {
            if (entry.getValue().size() > 1) {
                found++;
                System.out.println("INFO: The service " + entry.getKey() + " is defined on several packages: " + entry.getValue());
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display disabled services in packages");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        for (Entry<String,Set<String>> entry : inactiveServicesTracker.entrySet()) {
            found++;
            System.out.println("WARN: The service " + entry.getKey() + " defined on packages " + entry.getValue() + " is disabled");
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }

        System.out.println("-------------------------------------------------------------------------------");
        System.out.println("Config: Display configured services in packages without a monitor");
        System.out.println("-------------------------------------------------------------------------------");
        found = 0;
        for (Entry<String,Set<String>> entry : activeServicesTracker.entrySet()) {
            if (!pollerConfig.isServiceMonitored(entry.getKey())) {
                found++;
                System.out.println("WARN: The service " + entry.getKey() + " defined on packages " + entry.getValue() + " does not have any monitor associated");                
            }
        }
        if (found == 0) {
            System.out.println("Everything is OK");
        }
    }

    public void databaseCheck() throws Exception {
        transactionTemplate.execute(new TransactionCallback<Object>() {
            public Object doInTransaction(TransactionStatus status) {
                Map<String,Set<String>> notMonitored = new TreeMap<String,Set<String>>();
                Map<String,Set<String>> forcedUnmanaged = new TreeMap<String,Set<String>>();

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: Display services defined on several packages");
                System.out.println("Maybe this is intended, for example when overriding services.");
                System.out.println("-------------------------------------------------------------------------------");
                int found = 0;
                Set<String> monitoredServices = new TreeSet<String>();
                for (OnmsMonitoredService svc : monitoredServiceDao.findAll()) {
                    monitoredServices.add(svc.getServiceName());
                    OnmsNode node = svc.getIpInterface().getNode();

                    // Processing Active Services
                    if (svc.getStatus().equals("A")) {
                        Set<String> svcPackages = new TreeSet<String>();
                        List<String> packages = pollerConfig.getAllPackageMatches(svc.getIpAddress().getHostAddress());
                        for (String pkgName : packages) {
                            Package p = pollerConfig.getPackage(pkgName);
                            for (Service s : p.getServiceCollection()) {
                                if (s.getStatus().equals("on") && s.getName().equals(svc.getServiceName())) {
                                    svcPackages.add(pkgName);
                                }
                            }
                        }
                        if (svcPackages.size() > 1) {
                            found++;
                            System.out.println("INFO: The service " + svc.getServiceName() + " on node " + node.getLabel() + " is defined on multiple packages: " + svcPackages);
                        }
                    }

                    // Processing Not Monitored Services
                    // TODO: Check if the service was added through a detector or through a requisition.
                    if (svc.getStatus().equals("N")) {
                        if (!notMonitored.containsKey(node.getLabel())) {
                            notMonitored.put(node.getLabel(), new TreeSet<String>());
                        }
                        notMonitored.get(node.getLabel()).add(svc.getServiceName());
                    }

                    // Processing Unmanaged Services
                    // NOTE: The service must be handled through a detector or managed by Capsd.
                    if (svc.getStatus().equals("F")) {
                        if (!forcedUnmanaged.containsKey(node.getLabel())) {
                            forcedUnmanaged.put(node.getLabel(), new TreeSet<String>());
                        }
                        forcedUnmanaged.get(node.getLabel()).add(svc.getServiceName());
                    }
                }
                if (found == 0) {
                    System.out.println("Everything is OK");
                }

                int totalForcedUnmanaged = 0, totalNotMonitored = 0;

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: List of not monitored services per node");
                System.out.println("DB: Services associated with nodes that doesn't exist on any poller package");
                System.out.println("-------------------------------------------------------------------------------");
                Set<String> notMonitoredServices = new TreeSet<String>();
                if (notMonitored.isEmpty()) {
                    System.out.println("Everything is OK");
                } else {
                    for (Entry<String,Set<String>> entry : notMonitored.entrySet()) {
                        notMonitoredServices.addAll(entry.getValue());
                        System.out.println("WARN: The following services on node " + entry.getKey() + " are not monitored: " + entry.getValue());
                        totalNotMonitored += entry.getValue().size();
                    }
                }

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: List of not monitored services");
                System.out.println("DB: Services associated with nodes that doesn't exist on any poller package");
                System.out.println("-------------------------------------------------------------------------------");
                if (notMonitoredServices.isEmpty()) {
                    System.out.println("Everything is OK");
                } else {
                    for (String service : notMonitoredServices) {
                        System.out.println("WARN: The service " + service + " is not monitored on any node");
                    }
                }

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: List of forced unmanaged services per node");
                System.out.println("-------------------------------------------------------------------------------");
                if (forcedUnmanaged.isEmpty()) {
                    System.out.println("Everything is OK");
                } else {
                    for (Entry<String,Set<String>> entry : forcedUnmanaged.entrySet()) {
                        System.out.println("WARN: The following services on node " + entry.getKey() + " are forced unmanaged: " + entry.getValue());
                        totalForcedUnmanaged += entry.getValue().size();
                    }
                }

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: Display the services configured on packages not used on any nodes");
                System.out.println("-------------------------------------------------------------------------------");
                Map<String,Set<String>> activeMonitoredServices = new TreeMap<String,Set<String>>();
                for (Package p : ((PollerConfigManager) pollerConfig).packages()) {
                    for (Service s : p.getServiceCollection()) {
                        if (!activeMonitoredServices.containsKey(s.getName())) {
                            activeMonitoredServices.put(s.getName(), new TreeSet<String>());
                        }
                        if (s.getStatus().equals("on") && pollerConfig.isServiceMonitored(s.getName())) {
                            activeMonitoredServices.get(s.getName()).add(p.getName());
                        }
                    }
                }
                found = 0;
                for (Entry<String,Set<String>> entry : activeMonitoredServices.entrySet()) {
                    if (!monitoredServices.contains(entry.getKey())) {
                        found++;
                        System.out.println("WARN: The service " + entry.getKey() + " defined on packages " + entry.getValue() + " is not used on any node.");                        
                    }
                }
                if (found == 0) {
                    System.out.println("Everything is OK");
                }

                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("DB: Bad services statistics");
                System.out.println("-------------------------------------------------------------------------------");
                System.out.println("INFO: There are " + totalNotMonitored + " services not monitored");
                System.out.println("INFO: There are " + totalForcedUnmanaged + " services forced unmanaged");
                return null;
            }
        });
    }

    public Properties displayReport() throws Exception {
        return transactionTemplate.execute(new TransactionCallback<Properties>() {
            public Properties doInTransaction(TransactionStatus status) {
                Properties properties = new Properties();
                System.out.println("-------------------------------------------------------------------------------");
                for (OnmsMonitoredService svc : monitoredServiceDao.findAll()) {
                    if (!svc.getStatus().equals("A")) {
                        continue;
                    }
                    Package pkg = findPackageForService(svc.getIpAddress().getHostAddress(), svc.getServiceName());
                    Map<String,Object> parameters = getServiceParameters(svc.getServiceName(), pkg);
                    StringBuffer sb = new StringBuffer();
                    OnmsNode node = svc.getIpInterface().getNode();
                    sb.append("nodeLabel=").append(node.getLabel()).append(", ");
                    sb.append("ipAddress=").append(svc.getIpAddress().getHostName()).append(", ");
                    sb.append("serviceName=").append(svc.getServiceName()).append(", ");
                    sb.append("package=").append(pkg.getName()).append(", ");
                    sb.append("parameters=").append(parameters);
                    System.out.println(sb.toString());
                    properties.put(svc.getServiceName() + "@" + svc.getIpAddress().getHostName() , parameters.toString());
                }
                return properties;
            }
        });
    }

    public void testForcedUnmanaged() throws Exception {
        transactionTemplate.execute(new TransactionCallback<Object>() {
            public Object doInTransaction(TransactionStatus status) {
                double total = 0;
                double available = 0;
                for (OnmsMonitoredService svc : monitoredServiceDao.findAll()) {
                    if (!svc.getStatus().equals("F")) {
                        continue;
                    }
                    total++;
                    ServiceMonitor monitor = pollerConfig.getServiceMonitor(svc.getServiceName());
                    Package pkg = findPackageForService(svc.getIpAddress().getHostAddress(), svc.getServiceName());
                    final Map<String,Object> parameters = getServiceParameters(svc.getServiceName(), pkg);
                    SimpleMonitoredService service = new SimpleMonitoredService(svc);
                    System.out.print("Checking " + service + " with " + parameters + ". Available? ");
                    PollStatus pollStatus = monitor.poll(service, parameters);
                    boolean avail = pollStatus.getStatusCode() == PollStatus.SERVICE_AVAILABLE;
                    System.out.println(avail);
                    if (avail)
                        available++;
                }
                Double availP = (available/total) * 100;
                System.out.println("Total Forced Unmanaged = " + total);
                System.out.println("Total Available = " + available + " (" + availP + "%)");
                return null;
            }
        });
    }

    public void organizeMonitors() {
        Map<String,String> monitors = new TreeMap<String,String>();
        for (Monitor m : ((PollerConfigManager) pollerConfig).monitors()) {
            monitors.put(m.getService(), m.getClassName());
        }
        Map<String,Set<String>> servicesMap = new TreeMap<String,Set<String>>();
        for (Package p : ((PollerConfigManager) pollerConfig).packages()) {
            for (Service s : p.getServiceCollection()) {
                if (!servicesMap.containsKey(s.getName()))
                    servicesMap.put(s.getName(), new TreeSet<String>());
                servicesMap.get(s.getName()).add(p.getName());
            }
        }
        for (Entry<String,Set<String>> entry : servicesMap.entrySet()) {
            StringBuffer sb = new StringBuffer("  ");
            sb.append("<monitor service=\"").append(entry.getKey()).append("\"");
            sb.append(" class-name=\"").append(monitors.get(entry.getKey())).append("\"/>");
            sb.append(" <!-- ");
            sb.append(StringUtils.join(entry.getValue(), ", "));
            sb.append(" -->");
            System.out.println(sb.toString());
        }

    }

    protected Package findPackageForService(String ipAddr, String serviceName) {
        Enumeration<Package> en = pollerConfig.enumeratePackage();
        Package lastPkg = null;
        while (en.hasMoreElements()) {
            Package pkg = en.nextElement();
            if (pollableServiceInPackage(ipAddr, serviceName, pkg))
                lastPkg = pkg;
        }
        return lastPkg;
    }

    protected boolean pollableServiceInPackage(String ipAddr, String serviceName, Package pkg) {
        if (pkg.getRemote()) return false;
        if (!pollerConfig.isServiceInPackageAndEnabled(serviceName, pkg)) return false;        
        return pollerConfig.isInterfaceInPackage(ipAddr, pkg);
    }

    protected Map<String,Object> getServiceParameters(String serviceName, Package pkg) {
        Map<String,Object> parameters = new TreeMap<String,Object>();
        if (pkg == null)
            return parameters;
        for (Service s : pkg.getServiceCollection()) {
            if (s.getName().equalsIgnoreCase(serviceName)) {
                for (Parameter p : s.getParameterCollection()) {
                    String value = p.getValue();
                    if (value == null) {
                        value = p.getAnyObject().toString();
                        value = value.replaceAll("\\n", "").replaceAll("\\r", "").replaceAll("\\s{2,}", "");
                    }
                    parameters.put(p.getKey(), value);
                }
            }
        }
        return parameters;
    }
}
