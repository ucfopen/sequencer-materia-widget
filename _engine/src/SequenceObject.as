/* See the file "LICENSE.txt" for the full license governing this code. */
////////////////////////////////////////////////////////////////////////////////
//
//  UCF COURSE DEVELOPMENT AND WEB SERVICES
//  Copyright 2010 UCF Course Development and Web Services
//  All Rights Reserved.
//
//  NOTICE: Course Development and Webservices prohibits the use of the
//  following code without explicit permission.  Permission can be obtained
//  from the New Media team at <newmedia@mail.ucf.edu>.
//
////////////////////////////////////////////////////////////////////////////////
package
{
public class SequenceObject
{
	/**
	 * name of the object, visible at all times to the user
	 */
	public var name:String;
	/**
	 * description that is visible upon interaction
	 */
	public var description:String;
	/**
	 * correct order of this sequence object
	 */
	public var order:int;
	/**
	 * the question ID in the qset this is linked to
	 */
	public var id:String;
	/**
	 * constructor
	 */
	public function SequenceObject(name:String, description:String, order:int, id:String)
	{
		this.name        = name;
		this.description = description;
		this.order       = order;
		this.id          = id;
	}
}
}