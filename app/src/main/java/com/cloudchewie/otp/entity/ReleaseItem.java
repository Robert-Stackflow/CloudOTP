package com.cloudchewie.otp.entity;

import androidx.annotation.NonNull;

import com.google.gson.annotations.SerializedName;

import java.time.OffsetDateTime;

/**
 * Release，A release.
 */
public class ReleaseItem {
//    private ReleaseAsset[] assets;
    @SerializedName("assets_url")
    private String assetsUrl;
    private SimpleUser author;
    private String body;
    @SerializedName("body_html")
    private String bodyHtml;
    @SerializedName("body_text")
    private String bodyText;
    private OffsetDateTime createdAt;
    /**
     * true to create a draft (unpublished) release, false to create a published one.
     */
    private boolean draft;
    @SerializedName("html_url")
    private String htmlUrl;
    private long id;
    private String name;
    @SerializedName("node_id")
    private String nodeId;
    /**
     * Whether to identify the release as a prerelease or a full release.
     */
    private boolean prerelease;
    private OffsetDateTime publishedAt;
    private ReactionRollup reactions;
    /**
     * The name of the tag.
     */
    @SerializedName("tag_name")
    private String tagName;
    @SerializedName("tarball_url")
    private String tarballUrl;
    /**
     * Specifies the commitish value that determines where the Git tag is created from.
     */
    @SerializedName("target_commitish")
    private String targetCommitish;
    @SerializedName("upload_url")
    private String uploadUrl;
    private String url;
    @SerializedName("zipball_url")
    private String zipballUrl;

//    public ReleaseAsset[] getAssets() { return assets; }
//    public void setAssets(ReleaseAsset[] value) { this.assets = value; }

    public String getAssetsUrl() { return assetsUrl; }
    public void setAssetsUrl(String value) { this.assetsUrl = value; }

    public SimpleUser getAuthor() { return author; }
    public void setAuthor(SimpleUser value) { this.author = value; }

    public String getBody() { return body; }
    public void setBody(String value) { this.body = value; }

    public String getBodyHtml() { return bodyHtml; }
    public void setBodyHtml(String value) { this.bodyHtml = value; }

    public String getBodyText() { return bodyText; }
    public void setBodyText(String value) { this.bodyText = value; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime value) { this.createdAt = value; }

    public boolean getDraft() { return draft; }
    public void setDraft(boolean value) { this.draft = value; }

    public String getHtmlUrl() { return htmlUrl; }
    public void setHtmlUrl(String value) { this.htmlUrl = value; }

    public long getId() { return id; }
    public void setId(long value) { this.id = value; }

    public String getName() { return name; }
    public String getVersion() {
        return tagName.replaceAll("[a-zA-Z]", "");
    }
    public void setName(String value) { this.name = value; }

    public String getNodeId() { return nodeId; }
    public void setNodeId(String value) { this.nodeId = value; }

    public boolean getPrerelease() { return prerelease; }
    public void setPrerelease(boolean value) { this.prerelease = value; }

    public OffsetDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(OffsetDateTime value) { this.publishedAt = value; }

    public ReactionRollup getReactions() { return reactions; }
    public void setReactions(ReactionRollup value) { this.reactions = value; }

    public String getTagName() { return tagName; }
    public void setTagName(String value) { this.tagName = value; }

    public String getTarballUrl() { return tarballUrl; }
    public void setTarballUrl(String value) { this.tarballUrl = value; }

    public String getTargetCommitish() { return targetCommitish; }
    public void setTargetCommitish(String value) { this.targetCommitish = value; }

    public String getUploadUrl() { return uploadUrl; }
    public void setUploadUrl(String value) { this.uploadUrl = value; }

    public String getUrl() { return url; }
    public void setUrl(String value) { this.url = value; }

    public String getZipballUrl() { return zipballUrl; }
    public void setZipballUrl(String value) { this.zipballUrl = value; }

    @NonNull
    @Override
    public String toString() {
        return "ReleaseItem{" +
//                "assets=" + Arrays.toString(assets) +
                ", assetsUrl='" + assetsUrl + '\'' +
                ", author=" + author +
                ", body='" + body + '\'' +
                ", bodyHtml='" + bodyHtml + '\'' +
                ", bodyText='" + bodyText + '\'' +
                ", createdAt=" + createdAt +
                ", draft=" + draft +
                ", htmlUrl='" + htmlUrl + '\'' +
                ", id=" + id +
                ", name='" + name + '\'' +
                ", nodeId='" + nodeId + '\'' +
                ", prerelease=" + prerelease +
                ", publishedAt=" + publishedAt +
                ", reactions=" + reactions +
                ", tagName='" + tagName + '\'' +
                ", tarballUrl='" + tarballUrl + '\'' +
                ", targetCommitish='" + targetCommitish + '\'' +
                ", uploadUrl='" + uploadUrl + '\'' +
                ", url='" + url + '\'' +
                ", zipballUrl='" + zipballUrl + '\'' +
                '}';
    }
}

