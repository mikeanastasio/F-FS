//
//  ProfileViewController.swift
//  iOSFinalProject
//
//  Created by Michael Anastasio on 12/3/18.
//  Copyright © 2018 Michael Anastasio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileDescription: UILabel!
    @IBOutlet weak var schoolName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var postArray = [Post]()
    var sendingPost:Post!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        profileImage.image = UIImage(named: "noPhoto.png")
        
        let dbRef = Database.database().reference().child("Schools").child((Auth.auth().currentUser?.displayName)!).child("Users").queryOrdered(byChild: "email").queryEqual(toValue: Auth.auth().currentUser?.email)
        dbRef.observe(.value) { (snapshot) in
            if let dict = snapshot.value as? Dictionary<String, Any> {
                if let userInfo = dict.values.first as? Dictionary<String, Any> {
                    self.title = userInfo["username"] as? String
                    self.profileDescription.text = userInfo["description"] as? String
                    self.schoolName.text = Auth.auth().currentUser?.displayName
                    self.loadPosts(userInfo: userInfo)
                }
                //print(userInfo["username"])
            }
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    
    
    func loadPosts(userInfo: Dictionary<String, Any>) {
        Database.database().reference().child("Schools").child((Auth.auth().currentUser?.displayName)!).child("Posts").queryOrdered(byChild: "email").queryEqual(toValue: userInfo["email"]).observe(.childAdded) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let name = dict["name"] as! String
                let description = dict["description"] as! String
                //let email = dict["email"] as! String
                let price = dict["price"] as! String
                let imageUrl = dict["imageUrl"] as! String
                let storRef = Storage.storage().reference(forURL: imageUrl)
                let email = dict["email"] as? String ?? ""
                storRef.getData(maxSize: 1*2560*2560) { (data, error) in
                    if error == nil {
                        let image = UIImage(data: data!)
                        let post = Post(n: name, d: description, p: price, e: email, im: image!)
                        self.postArray.append(post)
                        self.tableView.reloadData()
                    }else{
                        print(error?.localizedDescription ?? "")
                    }
                }
            }
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        
        let post = postArray[indexPath.row]
        cell.postName.text = post.name
        cell.postPrice.text = post.price
        cell.postDescription.text = post.description
        cell.postImage.image = post.image
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sendingPost = postArray[indexPath.row]
        self.performSegue(withIdentifier: "ProfilePostSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ViewPostViewController {
            vc.post = self.sendingPost
            vc.name = sendingPost.name
            vc.price = sendingPost.price
            vc.desc = sendingPost.description
            vc.image = sendingPost.image
        }
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Are you sure you want to log out?", message: "", preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            do{
                try Auth.auth().signOut()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let signInVC = storyboard.instantiateViewController(withIdentifier: "SignInViewController")
                self.present(signInVC, animated: true, completion: nil)
            }catch let error {
                print(error.localizedDescription)
            }
        }
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}
