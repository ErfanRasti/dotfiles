// Brings back Spotify's old "Expand cover art" button (removed upstream): hover the
// playbar thumbnail and click the arrow to show the cover large above the playbar;
// the arrow on the large cover collapses it again. The state is remembered.
(function coverExpand() {
	const bar = document.querySelector(".Root__now-playing-bar");
	if (!window.Spicetify?.Player?.addEventListener || !bar) {
		setTimeout(coverExpand, 300);
		return;
	}

	const style = document.createElement("style");
	style.textContent = `
		.Root__now-playing-bar { position: relative; }
		.cover-expand-btn {
			position: absolute; top: 4px; right: 4px;
			display: flex; align-items: center; justify-content: center;
			width: 24px; height: 24px; padding: 0; border: 0; border-radius: 50%;
			background: rgba(0, 0, 0, 0.7); color: #fff; cursor: pointer;
			opacity: 0; transition: opacity 0.15s, transform 0.15s;
		}
		.cover-expand-btn:hover { transform: scale(1.08); }
		.main-coverSlotCollapsed-container:hover .cover-expand-btn,
		#cover-expand-panel:hover .cover-expand-btn { opacity: 1; }
		#cover-expand-panel {
			display: none; position: absolute; left: 8px; bottom: calc(100% + 8px);
			width: min(280px, 30vw); aspect-ratio: 1;
			border-radius: 8px; overflow: hidden;
			box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
		}
		#cover-expand-panel img { display: block; width: 100%; height: 100%; object-fit: cover; }
		.cover-expanded #cover-expand-panel { display: block; }
		.cover-expanded .main-coverSlotCollapsed-container { display: none; }
	`;
	document.head.appendChild(style);

	const setOpen = open => {
		document.body.classList.toggle("cover-expanded", open);
		localStorage.setItem("cover-expand:open", open ? "1" : "0");
	};
	const button = (title, path, open) => {
		const b = document.createElement("button");
		b.className = "cover-expand-btn";
		b.title = title;
		b.innerHTML = `<svg viewBox="0 0 16 16" width="16" height="16" fill="currentColor"><path d="${path}"/></svg>`;
		b.addEventListener("click", e => {
			e.stopPropagation(); // the thumbnail itself opens the Now Playing view
			setOpen(open);
		});
		return b;
	};

	// Inside the playbar, so CSS keeps it just above it (taller with the "Playing on" bar)
	const panel = document.createElement("div");
	panel.id = "cover-expand-panel";
	const img = document.createElement("img");
	panel.append(img, button("Collapse cover art", "M2 6l6 6 6-6-1.4-1.4L8 9.2 3.4 4.6z", false));
	bar.appendChild(panel);

	// React re-renders the thumbnail, so re-attach the expand button when needed
	const expandBtn = button("Expand cover art", "M14 10 8 4l-6 6 1.4 1.4L8 6.8l4.6 4.6z", true);
	const attach = () => {
		const cover = bar.querySelector(".main-coverSlotCollapsed-container");
		if (cover && expandBtn.parentElement !== cover) cover.appendChild(expandBtn);
	};
	new MutationObserver(attach).observe(bar, { childList: true, subtree: true });
	attach();

	// Returns false while Spotify hasn't loaded the current track yet
	const updateCover = () => {
		const m = Spicetify.Player.data?.item?.metadata;
		const url = m?.image_xlarge_url || m?.image_large_url || m?.image_url;
		if (url) img.src = url.replace("spotify:image:", "https://i.scdn.co/image/");
		return !!url;
	};
	Spicetify.Player.addEventListener("songchange", updateCover);
	// At startup the track loads after this runs, and no songchange follows if the
	// same song resumes, so keep trying until there's a cover
	(function waitForTrack() {
		if (!updateCover()) setTimeout(waitForTrack, 500);
	})();

	setOpen(localStorage.getItem("cover-expand:open") === "1");
})();
