package org.opennms.tools;

import java.net.InetAddress;

import org.opennms.core.utils.InetAddressUtils;
import org.opennms.netmgt.model.OnmsMonitoredService;
import org.opennms.netmgt.poller.InetNetworkInterface;
import org.opennms.netmgt.poller.MonitoredService;
import org.opennms.netmgt.poller.NetworkInterface;

public class SimpleMonitoredService implements MonitoredService {

    private final int m_nodeId;
    private String m_nodeLabel;
    private final String m_ipAddr;
    private final String m_svcName;
    private InetAddress m_inetAddr;

    public SimpleMonitoredService(OnmsMonitoredService svc) {
        m_nodeId = svc.getNodeId();
        m_nodeLabel = svc.getIpInterface().getNode().getLabel();
        m_inetAddr = svc.getIpAddress();
        m_svcName = svc.getServiceName();
        m_ipAddr = InetAddressUtils.str(m_inetAddr);
    }

    public String getSvcName() {
        return m_svcName;
    }

    public String getIpAddr() {
        return m_ipAddr;
    }

    public int getNodeId() {
        return m_nodeId;
    }

    public String getNodeLabel() {
        return m_nodeLabel;
    }

    public void setNodeLabel(String nodeLabel) {
        m_nodeLabel = nodeLabel;
    }

    public NetworkInterface<InetAddress> getNetInterface() {
        return new InetNetworkInterface(m_inetAddr);
    }

    public InetAddress getAddress() {
        return m_inetAddr;
    }

    public String getSvcUrl() {
        return null;
    }

    @Override
    public String toString() {
        return "[nodeId=" + m_nodeId + ", nodeLabel=" + m_nodeLabel + ", ipAddress=" + m_inetAddr.getHostAddress() + ", svcName=" + m_svcName + "]";
    }

}
