---
layout: page
title: 
subtitle:  
permalink:
---

<div class="home-container">
  <section class="hero-section">
    <div class="hero-content">
      <img src="/assets/images/florijan.png" alt="Florijan Klezin" class="hero-avatar">
      <div class="hero-text">
        <p class="hero-bio">Senior Data Engineer with 8+ years of experience building large-scale, cloud-native data platforms. I design cost-efficient infrastructure, reduce data latency, and enable advanced analytics in mission-critical environments.</p>
        <p class="hero-location">Currently working with AWS, Python, and modern data stack tools. Based in Slovenia.</p>
      </div>
    </div>
  </section>

  <section class="featured-section">
    <h2 class="section-title">Featured Projects</h2>
    <div class="featured-grid">
      <div class="featured-card">
        <h3 class="featured-title">🦆 DuckDB SiStat Extension</h3>
        <p class="featured-description">Query Slovenia's SiStat open data portal directly from DuckDB using SQL. No external ETL required.</p>
        <a href="https://github.com/fklezin/duckdb-sistat" class="featured-link">View on GitHub →</a>
      </div>
      <div class="featured-card">
        <h3 class="featured-title">📱 UPN to EPC QR Converter</h3>
        <p class="featured-description">Scan a Slovenian UPN payment QR and convert it to the European EPC standard.</p>
        <a href="/qr.upn/" class="featured-link">Try it now →</a>
      </div>
    </div>
  </section>

  <section class="blog-section">
    <div class="section-header">
      <h2 class="section-title">Recent Blog Posts</h2>
      <a href="/blog.html" class="view-all-link">View all →</a>
    </div>
    <ul class="post-list">
      {% for post in site.posts limit:5 %}
        <li class="post-item">
          <a href="{{ post.url | prepend: site.baseurl }}" class="post-link">
            <div class="post-content">
              <span class="post-title">{{ post.title }}</span>
              <span class="post-date">{{ post.date | date: "%b %d, %Y" }}</span>
              {% if post.excerpt %}
                <p class="post-excerpt">{{ post.excerpt | strip_html | truncatewords: 30 }}</p>
              {% endif %}
            </div>
          </a>
        </li>
      {% endfor %}
    </ul>
  </section>

  <section class="contact-section">
    <h2 class="section-title">Let's Connect</h2>
    <p class="contact-text">Interested in working together or discussing data engineering?</p>
    <a href="mailto:klezin.florijan95@gmail.com" class="contact-button">Get in Touch</a>
  </section>
</div>





