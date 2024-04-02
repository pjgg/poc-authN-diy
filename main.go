package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"

	"github.com/dgrijalva/jwt-go"
	"golang.org/x/oauth2"
)

func main() {
	var err error
	var accessTokenGenJWT AccessTokenGenJWT
	if accessTokenGenJWT.PrivateKey, err = jwt.ParseRSAPrivateKeyFromPEM(privatekeyPEM); err != nil {
		fmt.Printf("ERROR: %s\n", err)
		return
	}

	if accessTokenGenJWT.PublicKey, err = jwt.ParseRSAPublicKeyFromPEM(publickeyPEM); err != nil {
		fmt.Printf("ERROR: %s\n", err)
		return
	}

	client := &oauth2.Config{
		ClientID:     "53fb2f936d2814d0e899",
		ClientSecret: "4e072cb672dacb0d5d159116ab87ebd1b9f8d01e",
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://github.com/login/oauth/authorize",
			TokenURL: "https://github.com/login/oauth/access_token",
		},
		RedirectURL: "http://localhost:14000/appauth/callback",
	}

	// Application home endpoint
	http.HandleFunc("/app", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("<html><body>"))
		w.Write([]byte(fmt.Sprintf("<a href=\"%s\">Login</a><br/>", client.AuthCodeURL("BMW")))) // We could use the state to propagate the OrgID between the auth and the callback
		w.Write([]byte("</body></html>"))
	})

	// Application destination - CODE
	http.HandleFunc("/appauth/callback", func(w http.ResponseWriter, r *http.Request) {
		r.ParseForm()
		incomingCode := r.Form.Get("code")
		state := r.Form.Get("state")

		fmt.Println("state: " + state)

		clientID := "53fb2f936d2814d0e899"
		clientSecret := "4e072cb672dacb0d5d159116ab87ebd1b9f8d01e"
		redirectURI := "http://localhost:14000/appauth/callback"

		data := url.Values{}
		data.Set("client_id", clientID)
		data.Set("client_secret", clientSecret)
		data.Set("code", incomingCode)
		data.Set("redirect_uri", redirectURI)
		data.Set("grant_type", "authorization_code")

		req, err := http.NewRequest("POST", "https://github.com/login/oauth/access_token", bytes.NewBufferString(data.Encode()))
		if err != nil {
			fmt.Println("Error creating request:", err)
			return
		}
		req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
		req.SetBasicAuth(clientID, clientSecret)

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			fmt.Println("Error making request:", err)
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			fmt.Println("Unexpected response status:", resp.Status)
			return
		}

		body, err := ioutil.ReadAll(resp.Body)
		formData, err := url.ParseQuery(string(body))
		if err != nil {
			fmt.Println("Error parsing response body:", err)
			return
		}

		accessToken := formData.Get("access_token")

		fmt.Println("Github accessToken: " + accessToken)

		jwt, _, err := accessTokenGenJWT.GenerateAccessToken(clientID, false)
		if err != nil {
			fmt.Println("Error generating JWT:", err)
			return
		}

		// Create cookie with access token
		http.SetCookie(w, &http.Cookie{
			Name:  "jwtToken",
			Value: jwt,
		})

		http.Redirect(w, r, "http://localhost:14000/app", http.StatusFound)
	})

	http.ListenAndServe(":14000", nil)
}
