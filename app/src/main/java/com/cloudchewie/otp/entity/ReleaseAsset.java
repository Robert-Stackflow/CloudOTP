package com.cloudchewie.otp.entity;

import java.time.OffsetDateTime;

public class ReleaseAsset {
    private String browserDownloadUrl;
    private String contentType;
    private OffsetDateTime createdAt;
    private long downloadCount;
    private long id;
    private String label;
    /**
     * The file name of the asset.
     */
    private String name;
    private String nodeId;
    private long size;
    /**
     * State of the release asset.
     */
    private RleaseState state;
    private OffsetDateTime updatedAt;
    private Object uploader;
    private String url;

    public String getBrowserDownloadUrl() { return browserDownloadUrl; }
    public void setBrowserDownloadUrl(String value) { this.browserDownloadUrl = value; }

    public String getContentType() { return contentType; }
    public void setContentType(String value) { this.contentType = value; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime value) { this.createdAt = value; }

    public long getDownloadCount() { return downloadCount; }
    public void setDownloadCount(long value) { this.downloadCount = value; }

    public long getId() { return id; }
    public void setId(long value) { this.id = value; }

    public String getLabel() { return label; }
    public void setLabel(String value) { this.label = value; }

    public String getName() { return name; }
    public void setName(String value) { this.name = value; }

    public String getNodeId() { return nodeId; }
    public void setNodeId(String value) { this.nodeId = value; }

    public long getSize() { return size; }
    public void setSize(long value) { this.size = value; }

    public RleaseState getState() { return state; }
    public void setState(RleaseState value) { this.state = value; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime value) { this.updatedAt = value; }

    public Object getUploader() { return uploader; }
    public void setUploader(Object value) { this.uploader = value; }

    public String getUrl() { return url; }
    public void setUrl(String value) { this.url = value; }
}