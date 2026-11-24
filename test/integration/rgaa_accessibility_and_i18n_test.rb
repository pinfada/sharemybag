require 'test_helper'

class RgaaAccessibilityAndI18nTest < ActionDispatch::IntegrationTest
  test "toutes les pages publiques sont en anglais (lang=en) avec landmarks RGAA, lien d'évitement et un seul h1" do
    req = create_shipping_request(title: "Textbooks to Dakar")

    [
      root_path,
      shipping_requests_path,
      shipping_request_path(req),
      how_it_works_path,
      privacy_path,
      accessibility_path,
      signin_path,
      signup_path
    ].each do |path|
      get path
      assert_response :success, "Expected 200 on #{path}"
      assert_select "html[lang='en']", 1, "Missing lang='en' on #{path}"
      assert_select "title", /ShareMyBag/, "Missing ShareMyBag in title on #{path}"
      assert_select "a.smb-skip-link[href='#main-content']", 1, "Missing RGAA skip link on #{path}"
      assert_select "header[role='banner']", 1, "Missing banner landmark on #{path}"
      assert_select "nav[aria-label]", { minimum: 1 }, "Missing labeled nav on #{path}"
      assert_select "main#main-content[tabindex='-1']", 1, "Missing main landmark on #{path}"
      assert_select "footer[role='contentinfo']", 1, "Missing contentinfo landmark on #{path}"
      assert_select "h1", 1, "Expected exactly one h1 on #{path}"
    end
  end

  test "la navigation indique la page courante avec aria-current='page'" do
    get shipping_requests_path
    assert_response :success
    assert_select "nav a.nav-link[aria-current='page']", text: /Shipping requests/i
  end

  test "le formulaire de publication utilise fieldset/legend, aria-required et expose aria-invalid en cas d'erreur" do
    user = create_user
    sign_in_as(user)

    get new_shipping_request_path
    assert_response :success
    assert_select "fieldset legend", { minimum: 3 }
    assert_select "input[required][aria-required='true']", { minimum: 5 }

    # Soumission invalide -> résumé role="alert" et champs aria-invalid="true"
    post shipping_requests_path, params: {
      shipping_request: {
        title: "",
        weight_kg: "",
        departure_city: "",
        departure_country: "",
        arrival_city: "",
        arrival_country: "",
        desired_date: "",
        prohibited_items_acknowledged: "0"
      }
    }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", { minimum: 1 }
    assert_select "[aria-invalid='true']", { minimum: 1 }
  end

  test "le formulaire d'offre inclut une région aria-live pour le calcul du total" do
    sender = create_user
    traveler = create_user
    req = create_shipping_request(sender: sender)

    sign_in_as(traveler)
    get shipping_request_path(req)
    assert_response :success
    assert_select "[aria-live='polite'][data-bid-total-output]", 1
  end

  test "la page déclaration d'accessibilité RGAA est accessible et liée depuis le pied de page" do
    get root_path
    assert_select "footer a[href='#{accessibility_path}']", /Accessibility/i
    assert_select "link[rel='icon'][href='/favicon.svg']", 1
    assert_select "header svg.smb-logo-svg", 1

    get accessibility_path
    assert_response :success
    assert_includes response.body, "RGAA"
    assert_includes response.body, "WCAG 2.1"
  end
end
