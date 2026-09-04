document.getElementById('shorten-form').addEventListener('submit', async(e)=>{
    e.preventDefault()

    const longUrl = document.getElementById('long-url').value;
    const response = await fetch('/api/shorten', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ originalUrl: longUrl })
    });

    const data = await response.json();

    if(data.shortUrl){
        document.getElementById('result').innerHTML =
      `<p>Shortened URL: <a href="${data.shortUrl}" target="_blank">${data.shortUrl}</a></p>`;
    } 
    else{
        document.getElementById('result').textContent = 'Something went wrong';
    }

})